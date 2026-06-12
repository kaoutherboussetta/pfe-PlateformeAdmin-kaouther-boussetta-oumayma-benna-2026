<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class SatelliteController extends Controller
{
    private const RADIUS_KM = 25;

    /**
     * Résumé « analyse satellite » pour le dashboard : couverture nuageuse (proxy Open-Meteo)
     * + signalements de voirie dans un rayon autour du point GPS.
     */
    public function dashboardSummary($lat, $lon)
    {
        $lat = filter_var($lat, FILTER_VALIDATE_FLOAT);
        $lon = filter_var($lon, FILTER_VALIDATE_FLOAT);
        if ($lat === false || $lon === false || abs($lat) > 90 || abs($lon) > 180) {
            return response()->json(['error' => 'Coordonnées invalides'], 422);
        }

        $cloudCover = null;
        $apiTime = null;

        $response = Http::timeout(12)->get('https://api.open-meteo.com/v1/forecast', [
            'latitude' => $lat,
            'longitude' => $lon,
            'current' => 'cloud_cover',
            'timezone' => 'auto',
        ]);

        if ($response->successful()) {
            $data = $response->json();
            if (isset($data['current']['cloud_cover'])) {
                $cloudCover = (int) round((float) $data['current']['cloud_cover']);
            }
            $apiTime = $data['current']['time'] ?? null;
        }

        $zones = 0;
        $anomalies = 0;
        $latestCarbon = null;

        try {
            $raw = DB::connection('mongodb')->table('problemes_de_voirie')->get();
            foreach ($raw as $item) {
                $row = is_array($item) ? $item : (array) $item;
                $coords = self::pickCoords($row);
                if ($coords === null) {
                    continue;
                }
                [$pLat, $pLon] = $coords;
                if (self::haversineKm((float) $lat, (float) $lon, $pLat, $pLon) > self::RADIUS_KM) {
                    continue;
                }

                $zones++;

                $riskScore = (int) self::pickValue($row, ['score_risque', 'risk_score', 'score', 'riskScore'], 0);
                $riskScore = max(0, min($riskScore, 100));
                $priority = (int) self::pickValue($row, ['priorite', 'priority', 'priority_level'], 0);
                if ($priority <= 0) {
                    $priority = max(1, min(6, (int) ceil((101 - $riskScore) / 17)));
                }
                $severity = (string) self::pickValue($row, ['gravite', 'severity'], '');

                if (self::isHighPriorityAnomaly($riskScore, $severity, $priority)) {
                    $anomalies++;
                }

                $dt = self::parseProblemTimestamp($row);
                if ($dt !== null && ($latestCarbon === null || $dt->gt($latestCarbon))) {
                    $latestCarbon = $dt;
                }
            }
        } catch (\Throwable $e) {
            // Données partielles (météo / compteurs voirie)
        }

        $lastUpdateHuman = 'À l\'instant';
        if ($latestCarbon !== null) {
            $lastUpdateHuman = $latestCarbon->locale('fr')->diffForHumans();
        } elseif ($apiTime !== null) {
            try {
                $lastUpdateHuman = Carbon::parse($apiTime)->locale('fr')->diffForHumans();
            } catch (\Throwable $e) {
                // garder défaut
            }
        }

        return response()->json([
            'last_update_relative' => $lastUpdateHuman,
            'monitored_zones_count' => $zones,
            'anomalies_count' => $anomalies,
            'cloud_cover_pct' => $cloudCover,
            'radius_km' => self::RADIUS_KM,
            'latitude' => (float) $lat,
            'longitude' => (float) $lon,
        ]);
    }

    private static function pickValue(array $row, array $keys, $default = null)
    {
        foreach ($keys as $key) {
            $value = data_get($row, $key);
            if ($value !== null && $value !== '') {
                return $value;
            }
        }

        return $default;
    }

    /**
     * @return array{0: float, 1: float}|null
     */
    private static function pickCoords(array $row): ?array
    {
        $lat = self::pickValue($row, ['location.lat', 'lat', 'latitude'], null);
        $lon = self::pickValue($row, ['location.lon', 'location.lng', 'lon', 'lng', 'longitude'], null);

        if (! is_numeric($lat) || ! is_numeric($lon)) {
            $coords = data_get($row, 'location.coordinates');
            if (is_array($coords) && count($coords) >= 2
                && is_numeric($coords[0]) && is_numeric($coords[1])) {
                $lon = (float) $coords[0];
                $lat = (float) $coords[1];
            }
        }

        if (! is_numeric($lat) || ! is_numeric($lon)) {
            return null;
        }

        return [(float) $lat, (float) $lon];
    }

    private static function haversineKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthKm = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

        return $earthKm * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    private static function isHighPriorityAnomaly(int $riskScore, string $severity, int $priority): bool
    {
        $s = mb_strtolower($severity);

        return $riskScore >= 70
            || str_contains($s, 'critique')
            || str_contains($s, 'élev')
            || $priority <= 2;
    }

    private static function parseProblemTimestamp(array $row): ?Carbon
    {
        $rawDate = self::pickValue($row, ['updated_at', 'date_detection', 'detected_at', 'created_at', 'date'], null);
        if ($rawDate === null) {
            return null;
        }

        try {
            if ($rawDate instanceof \MongoDB\BSON\UTCDateTime) {
                return Carbon::instance($rawDate->toDateTime());
            }
            if ($rawDate instanceof \DateTimeInterface) {
                return Carbon::instance($rawDate);
            }

            return Carbon::parse((string) $rawDate);
        } catch (\Throwable $e) {
            return null;
        }
    }
}
