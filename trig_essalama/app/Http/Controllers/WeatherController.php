<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class WeatherController extends Controller
{
    /**
     * Récupère les données météo pour une position GPS donnée
     *
     * @param float $lat Latitude
     * @param float $lon Longitude
     * @return \Illuminate\Http\JsonResponse
     */
    public function getWeather($lat, $lon)
    {
        $response = Http::get(
            "https://api.open-meteo.com/v1/forecast",
            [
                'latitude' => $lat,
                'longitude' => $lon,
                'hourly' => 'precipitation'
            ]
        );

        $data = $response->json();

        return response()->json($data);
    }

    /**
     * Analyse les données météo et retourne une alerte si nécessaire
     *
     * @param float $lat Latitude
     * @param float $lon Longitude
     * @return \Illuminate\Http\JsonResponse
     */
    public function getWeatherAlert($lat, $lon)
    {
        $response = Http::get(
            "https://api.open-meteo.com/v1/forecast",
            [
                'latitude' => $lat,
                'longitude' => $lon,
                'hourly' => 'precipitation'
            ]
        );

        $data = $response->json();

        // Analyser les données de précipitation
        $alert = null;
        $rain = 0;

        if (isset($data['hourly']['precipitation']) && count($data['hourly']['precipitation']) > 0) {
            $rain = $data['hourly']['precipitation'][0];

            if ($rain > 5) {
                $alert = "Risque inondation";
            } elseif ($rain > 1) {
                $alert = "Route mouillée - Risque route glissante";
            } else {
                $alert = "Normal";
            }
        }

        return response()->json([
            'precipitation' => $rain,
            'alert' => $alert,
            'data' => $data
        ]);
    }

    /**
     * Analyse les risques météo et retourne un message d'alerte
     *
     * @param float $lat Latitude
     * @param float $lon Longitude
     * @return \Illuminate\Http\JsonResponse
     */
    public function weatherRisk($lat, $lon)
    {
        $response = Http::get(
            "https://api.open-meteo.com/v1/forecast",
            [
                'latitude' => $lat,
                'longitude' => $lon,
                'hourly' => 'precipitation'
            ]
        );

        $data = $response->json();

        $rain = 0;
        $riskLevel = 'normal';
        $message = '✔️ Conditions normales';

        if (isset($data['hourly']['precipitation']) && count($data['hourly']['precipitation']) > 0) {
            $rain = $data['hourly']['precipitation'][0];

            if ($rain > 5) {
                $riskLevel = 'inondation';
                $message = '⚠️ Risque inondation';
            } elseif ($rain > 1) {
                $riskLevel = 'route_mouillee';
                $message = '⚠️ Route mouillée';
            } else {
                $riskLevel = 'normal';
                $message = '✔️ Conditions normales';
            }
        }

        return response()->json([
            'precipitation' => $rain,
            'risk_level' => $riskLevel,
            'message' => $message,
            'data' => $data
        ]);
    }

    /**
     * Données météo condensées pour le widget dashboard (température, pluie, vent, risque inondation).
     * Source : Open-Meteo (gratuit, sans clé).
     */
    public function dashboardSummary($lat, $lon)
    {
        $lat = filter_var($lat, FILTER_VALIDATE_FLOAT);
        $lon = filter_var($lon, FILTER_VALIDATE_FLOAT);
        if ($lat === false || $lon === false || abs($lat) > 90 || abs($lon) > 180) {
            return response()->json(['error' => 'Coordonnées invalides'], 422);
        }

        $response = Http::timeout(12)->get('https://api.open-meteo.com/v1/forecast', [
            'latitude' => $lat,
            'longitude' => $lon,
            'current' => 'temperature_2m,wind_speed_10m,precipitation',
            'hourly' => 'precipitation',
            'windspeed_unit' => 'kmh',
            'timezone' => 'auto',
            'forecast_days' => 1,
        ]);

        if (! $response->successful()) {
            return response()->json(['error' => 'Service météo indisponible'], 502);
        }

        $data = $response->json();
        $current = $data['current'] ?? [];
        $temp = $current['temperature_2m'] ?? null;
        $wind = $current['wind_speed_10m'] ?? null;
        $tz = (string) ($data['timezone'] ?? 'UTC');
        $currentTime = $current['time'] ?? null;

        // Précipitations : utiliser la tranche horaire alignée sur `current.time` (mm/h cohérent avec l’heure affichée)
        $hourlyTimes = $data['hourly']['time'] ?? [];
        $hourlyPrecip = $data['hourly']['precipitation'] ?? [];
        $rain = 0.0;
        if ($currentTime && is_array($hourlyTimes) && is_array($hourlyPrecip)) {
            $idx = array_search($currentTime, $hourlyTimes, true);
            if ($idx !== false && isset($hourlyPrecip[$idx])) {
                $rain = (float) $hourlyPrecip[$idx];
            } elseif (isset($hourlyPrecip[0])) {
                $rain = (float) $hourlyPrecip[0];
            }
        }
        if ($rain <= 0.0 && isset($current['precipitation'])) {
            $rain = (float) $current['precipitation'];
        }

        if ($rain > 5) {
            $floodLabel = 'Élevé';
            $floodLevel = 'high';
        } elseif ($rain > 1) {
            $floodLabel = 'Modéré';
            $floodLevel = 'medium';
        } else {
            $floodLabel = 'Faible';
            $floodLevel = 'low';
        }

        $observedAtFr = null;
        if ($currentTime) {
            try {
                $observedAtFr = Carbon::parse($currentTime, $tz)
                    ->locale('fr_FR')
                    ->isoFormat('D MMM YYYY · HH:mm');
            } catch (\Throwable $e) {
                $observedAtFr = null;
            }
        }

        return response()->json([
            'temperature_c' => $temp !== null ? round((float) $temp, 1) : null,
            'precipitation_mm_h' => round($rain, 1),
            'wind_kmh' => $wind !== null ? round((float) $wind, 0) : null,
            'flood_risk_label' => $floodLabel,
            'flood_risk_level' => $floodLevel,
            'latitude' => (float) $lat,
            'longitude' => (float) $lon,
            'observed_at' => $currentTime,
            'observed_at_fr' => $observedAtFr,
            'timezone' => $tz,
        ]);
    }
}
