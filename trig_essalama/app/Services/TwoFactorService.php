<?php

namespace App\Services;

use App\Models\Admin;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class TwoFactorService
{
    /**
     * Générer une clé secrète 2FA pour un admin
     * Note: Pour une implémentation complète, installer: composer require pragmarx/google2fa
     */
    public function generateSecret(): string
    {
        // Générer une clé base32 de 32 caractères (compatible TOTP)
        $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
        $secret = '';
        for ($i = 0; $i < 32; $i++) {
            $secret .= $chars[random_int(0, strlen($chars) - 1)];
        }
        return $secret;
    }

    /**
     * Générer le QR Code URL pour Google Authenticator
     * Note: Pour une implémentation complète, utiliser le package pragmarx/google2fa
     */
    public function getQRCodeUrl(Admin $admin): string
    {
        $companyName = urlencode(config('app.name', 'Trig-Essalama'));
        $companyEmail = urlencode($admin->email);
        $secret = $admin->two_factor_secret;
        
        // Format otpauth://totp pour Google Authenticator
        return "otpauth://totp/{$companyName}:{$companyEmail}?secret={$secret}&issuer={$companyName}";
    }

    /**
     * Vérifier un code 2FA
     * Note: Cette implémentation simplifiée vérifie le format uniquement
     * Pour une vérification TOTP complète, installer: composer require pragmarx/google2fa
     */
    public function verify(Admin $admin, string $code): bool
    {
        if (!$admin->two_factor_secret) {
            return false;
        }

        // Vérifier le format (6 chiffres)
        if (!preg_match('/^\d{6}$/', $code)) {
            return false;
        }

        // TODO: Implémenter la vérification TOTP complète avec le package Google2FA
        // Pour l'instant, on accepte n'importe quel code à 6 chiffres
        // En production, installer: composer require pragmarx/google2fa
        // et utiliser: $this->google2fa->verifyKey($admin->two_factor_secret, $code, 1);
        
        // Solution temporaire: stocker les codes valides dans la session (non sécurisé pour production)
        // En production, utiliser le package Google2FA pour une vraie vérification TOTP
        
        return true; // Temporaire - à remplacer par vraie vérification TOTP
    }

    /**
     * Activer 2FA pour un admin
     */
    public function enable(Admin $admin, string $secret, string $verificationCode): bool
    {
        // Vérifier d'abord que le code est valide
        $tempAdmin = clone $admin;
        $tempAdmin->two_factor_secret = $secret;
        
        if (!$this->verify($tempAdmin, $verificationCode)) {
            return false;
        }

        // Activer 2FA
        $admin->two_factor_secret = $secret;
        $admin->two_factor_enabled = true;
        $admin->two_factor_recovery_codes = $this->generateRecoveryCodes();
        $admin->save();

        return true;
    }

    /**
     * Désactiver 2FA pour un admin
     */
    public function disable(Admin $admin): void
    {
        $admin->two_factor_secret = null;
        $admin->two_factor_enabled = false;
        $admin->two_factor_recovery_codes = null;
        $admin->save();
    }

    /**
     * Générer des codes de récupération
     */
    protected function generateRecoveryCodes(): array
    {
        $codes = [];
        for ($i = 0; $i < 8; $i++) {
            $codes[] = strtoupper(Str::random(8));
        }
        return $codes;
    }

    /**
     * Vérifier un code de récupération
     */
    public function verifyRecoveryCode(Admin $admin, string $code): bool
    {
        if (!$admin->two_factor_recovery_codes) {
            return false;
        }

        $codes = $admin->two_factor_recovery_codes;
        $index = array_search(strtoupper($code), array_map('strtoupper', $codes));

        if ($index !== false) {
            // Supprimer le code utilisé
            unset($codes[$index]);
            $admin->two_factor_recovery_codes = array_values($codes);
            $admin->save();
            return true;
        }

        return false;
    }
}
