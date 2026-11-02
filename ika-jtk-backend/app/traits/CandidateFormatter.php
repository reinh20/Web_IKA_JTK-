<?php

namespace App\Traits;

use App\Models\Alumni;

trait CandidateFormatter
{
    /**
     * Format full candidate data and sync with the latest Alumni info.
     */
    protected function formatCandidate(array $cData): array
    {
        if (is_string($cData['misi'] ?? null)) $cData['misi'] = json_decode($cData['misi'], true) ?: [];
        if (is_string($cData['pengalaman'] ?? null)) $cData['pengalaman'] = json_decode($cData['pengalaman'], true) ?: [];
        if (is_string($cData['programKerja'] ?? null)) $cData['programKerja'] = json_decode($cData['programKerja'], true) ?: [];
        if (is_string($cData['prestasi'] ?? null)) $cData['prestasi'] = json_decode($cData['prestasi'], true) ?: [];

        if (!empty($cData['alumniId'])) {
            $alumni = Alumni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$cData['alumniId']]]);
            if ($alumni) {
                $cData['fotoUrl'] = $alumni->avatarUrl ?? $cData['fotoUrl'];
                $cData['nama'] = $alumni->nama ?? $cData['nama'];
            }
        }

        $cData['voteCount'] = (int)($cData['voteCount'] ?? 0);
        return $cData;
    }

    /**
     * Get the latest name and avatar for a summary candidate array.
     */
    protected function formatCandidateSummary($c): array
    {
        $fotoUrl = $c->fotoUrl;
        $nama = $c->nama;

        if (!empty($c->alumniId)) {
            $alumni = Alumni::findFirst(['conditions' => 'id = ?0 AND deletedAt IS NULL', 'bind' => [$c->alumniId]]);
            if ($alumni) {
                $fotoUrl = $alumni->avatarUrl ?? $fotoUrl;
                $nama = $alumni->nama ?? $nama;
            }
        }

        return [
            'id' => $c->id,
            'nomorUrut' => $c->nomorUrut,
            'nama' => $nama,
            'fotoUrl' => $fotoUrl,
            'voteCount' => (int)($c->voteCount ?? 0),
            'persentase' => 0.0,
        ];
    }
}
