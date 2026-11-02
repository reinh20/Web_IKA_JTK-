import { useEffect, useState } from 'react'
import api from '@/lib/api'
import { SectionCard } from '@/components/admin/SectionCard'
import { Input, Label } from '@/components/ui/Input'
import { RichTextEditor } from '@/components/ui/RichTextEditor'
import { Button } from '@/components/ui/Button'
import { toast } from '@/components/ui/Toast'
import { Save, ScrollText, CheckCircle2, AlertCircle } from 'lucide-react'

export const UserAgreementsPage = () => {
  const [termsTitle, setTermsTitle] = useState('Syarat & Ketentuan Pengguna (Terms & Conditions)')
  const [termsSubtitle, setTermsSubtitle] = useState('Perjanjian hukum, ketentuan keanggotaan, dan aturan penggunaan layanan Portal IKA JTK POLBAN.')
  const [termsLastUpdated, setTermsLastUpdated] = useState('16 Juli 2026')
  const [termsIntro, setTermsIntro] = useState('Selamat datang di Portal Resmi Ikatan Alumni Teknik Komputer Politeknik Negeri Bandung (IKA JTK POLBAN). Dokumen Syarat dan Ketentuan Pengguna ("Perjanjian") ini mengatur hak, kewajiban, dan batasan hukum antara Anda sebagai pengguna dengan organisasi IKA JTK POLBAN. Dengan mendaftar, mengakses, atau menggunakan layanan pada portal ini, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh isi ketentuan di bawah ini.')
  const [termsContent, setTermsContent] = useState('<h3>1. Kualifikasi dan Verifikasi Keanggotaan</h3><p>Portal ini disediakan khusus untuk melayani jejaring komunikasi dan profesional civitas akademika serta alumni Jurusan Teknik Komputer POLBAN:</p><ul><li>Pendaftaran akun wajib menggunakan identitas asli yang akurat, termasuk Nama Lengkap, Tahun Angkatan, dan Nomor Alumni / bukti kelulusan yang sah.</li><li>Setiap pendaftaran akun baru akan melalui proses verifikasi dan validasi oleh tim Admin / Pengurus IKA JTK POLBAN sebelum status akun diaktifkan secara penuh.</li><li>Tindakan memalsukan identitas akademik, memanipulasi data kelulusan, atau mengatasnamakan alumni lain merupakan pelanggaran hukum berat yang berakibat pada pembatalan akun permanen, pelaporan kepada almamater, serta tindakan hukum sesuai undang-undang yang berlaku.</li></ul><h3>2. Keamanan Akun dan Tanggung Jawab Pengguna</h3><ul><li><strong>Kerahasiaan Kredensial:</strong> Anda bertanggung jawab penuh untuk menjaga kerahasiaan username, kata sandi, serta token akses akun Anda.</li><li><strong>Aktivitas Akun:</strong> Segala bentuk aktivitas, transaksi, dan publikasi konten yang dilakukan melalui akun Anda sepenuhnya menjadi tanggung jawab Anda pribadi.</li><li><strong>Larangan Berbagi Akun:</strong> Akun alumni bersifat personal dan tidak dapat dialihkan, dipinjamkan, atau diperjualbelikan kepada pihak lain dalam kondisi apa pun.</li><li><strong>Pelaporan Insiden:</strong> Jika Anda mengetahui atau mencurigai adanya akses ilegal atau kebocoran kredensial pada akun Anda, Anda wajib segera melaporkannya kepada Pengurus IKA JTK.</li></ul><h3>3. Aturan Penggunaan Layanan (Acceptable Use Policy)</h3><p>Dalam berinteraksi dan memanfaatkan fitur Portal IKA JTK (seperti Direktori Alumni, Lowongan Kerja, Berita, dan Pemilu), setiap pengguna dilarang keras untuk:</p><ul><li>Mengunggah atau menyebarkan informasi palsu (hoaks), penipuan lowongan kerja fiktif, ujaran kebencian, pelecehan, rasisme, pornografi, atau konten yang menyinggung SARA.</li><li>Melakukan aktivitas yang merusak marwah, martabat, dan nama baik organisasi IKA JTK maupun almamater Politeknik Negeri Bandung.</li><li>Melakukan pengumpulan data massal (data scraping/crawling) terhadap direktori alumni atau kontak pribadi anggota tanpa izin tertulis dari Pengurus Pusat IKA JTK POLBAN.</li><li>Melakukan serangan siber, penyebaran virus/malware, atau manipulasi sistem pemungutan suara elektronik (E-Voting/Pemilu Alumni).</li></ul><h3>4. Hak Kekayaan Intelektual dan Lisensi Konten</h3><p>Seluruh hak cipta atas arsitektur sistem, desain grafis, logo organisasi, dan basis data Portal IKA JTK adalah milik sah IKA JTK POLBAN. Terkait konten yang Anda kirimkan (berita, testimoni, lowongan kerja):</p><ul><li><strong>Kepemilikan Konten:</strong> Anda tetap menjadi pemilik hak cipta atas materi/konten yang Anda tulis atau publikasikan di portal ini.</li><li><strong>Lisensi Penayangan:</strong> Dengan mengunggah konten ke dalam portal, Anda memberikan hak non-eksklusif, bebas royalti, dan dapat dialihkan kepada IKA JTK POLBAN untuk menayangkan, mendistribusikan, dan mempromosikan konten tersebut demi kemajuan komunitas alumni.</li><li><strong>Tanggung Jawab Hukum:</strong> Anda menjamin bahwa konten yang Anda unggah tidak melanggar hak cipta pihak ketiga mana pun dan membebaskan IKA JTK dari segala tuntutan hukum yang timbul dari konten Anda.</li></ul><h3>5. Batasan Tanggung Jawab (Limitation of Liability)</h3><p>Layanan portal ini disediakan sebagaimana adanya ("as is" dan "as available"). IKA JTK POLBAN berupaya maksimal menjaga keandalan dan keamanan portal, namun tidak memberikan jaminan bahwa layanan akan selalu bebas dari gangguan teknis, keterlambatan, atau pemeliharaan sistem. IKA JTK POLBAN juga tidak bertanggung jawab atas kerugian material maupun immaterial yang timbul akibat interaksi, kesepakatan karir/bisnis, atau transaksi langsung antar alumni yang dilakukan di luar platform portal.</p><h3>6. Sanksi, Pembatasan, dan Penghentian Layanan</h3><p>Pengurus dan Admin IKA JTK POLBAN memiliki hak prerogatif untuk memberikan peringatan tertulis, membatasi hak akses fitur (suspend), atau menonaktifkan akun secara permanen apabila pengguna terbukti melanggar Syarat dan Ketentuan Pengguna ini, melanggar Kode Etik Komunitas, atau merugikan kepentingan organisasi.</p><h3>7. Perubahan Ketentuan dan Hukum yang Berlaku</h3><p>IKA JTK POLBAN berhak untuk memperbarui atau mengubah Syarat dan Ketentuan Pengguna ini sewaktu-waktu agar selaras dengan perkembangan organisasi dan regulasi yang berlaku. Perubahan akan diinformasikan melalui portal. Perjanjian ini tunduk dan ditafsirkan berdasarkan Hukum Republik Indonesia. Segala sengketa yang timbul akan diselesaikan terlebih dahulu secara musyawarah dan kekeluargaan di bawah mediasi Pengurus Pusat IKA JTK POLBAN.</p>')
  const [loading, setLoading] = useState(false)
  const [saveStatus, setSaveStatus] = useState<{ type: 'success' | 'error' | 'loading' | null; message: string }>({ type: null, message: '' })

  useEffect(() => {
    fetchConfig()
  }, [])

  const fetchConfig = async () => {
    try {
      const data = await api.getPortalConfig().catch(() => ({}))
      if (data && data.terms_conditions) {
        setTermsTitle(data.terms_conditions.title || 'Syarat & Ketentuan Pengguna (Terms & Conditions)')
        setTermsSubtitle(data.terms_conditions.subtitle || 'Perjanjian hukum, ketentuan keanggotaan, dan aturan penggunaan layanan Portal IKA JTK POLBAN.')
        setTermsLastUpdated(data.terms_conditions.last_updated || '16 Juli 2026')
        setTermsIntro(data.terms_conditions.intro || '')
        setTermsContent(data.terms_conditions.content || '')
      }
    } catch (err) {
      // ignore
    }
  }

  const handleSave = async () => {
    setLoading(true)
    setSaveStatus({ type: 'loading', message: 'Sedang menyimpan Syarat & Ketentuan ke server...' })
    try {
      const current = await api.getPortalConfig().catch(() => ({}))
      const payload: Record<string, any> = {
        ...current,
        terms_conditions: {
          title: termsTitle,
          subtitle: termsSubtitle,
          last_updated: termsLastUpdated,
          intro: termsIntro,
          content: termsContent,
        },
      }
      await api.updatePortalConfig(payload)
      window.dispatchEvent(new Event('portal-config-updated'))
      const timeStr = new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
      setSaveStatus({ type: 'success', message: `Syarat & Ketentuan berhasil disimpan ke database pada ${timeStr} WIB` })
      toast('Syarat & Ketentuan berhasil disimpan', 'success')
    } catch (err: any) {
      const detail = err.response?.data?.detail || err.response?.data?.error || err.response?.data?.message || err.message || 'Terjadi kesalahan sistem yang tidak diketahui'
      setSaveStatus({ type: 'error', message: `Gagal menyimpan: ${detail}` })
      toast(`Gagal menyimpan: ${detail}`, 'error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-5xl mx-auto px-10 py-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <ScrollText className="h-6 w-6 text-primary" />
            Editor Syarat & Ketentuan (Terms & Conditions)
          </h1>
          <p className="text-gray-500 mt-2 text-sm">
            Kelola isi dokumen Syarat & Ketentuan Pengguna yang akan ditampilkan pada halaman registrasi dan portal umum IKA JTK.
          </p>
        </div>
        <Button
          onClick={handleSave}
          disabled={loading}
          leftIcon={<Save className="h-4 w-4" />}
        >
          {loading ? 'Menyimpan...' : 'Simpan Perubahan'}
        </Button>
      </div>

      {saveStatus.type && (
        <div
          className={`p-4 rounded-lg border flex items-center justify-between gap-3 animate-in fade-in-50 ${
            saveStatus.type === 'loading'
              ? 'bg-blue-50 border-blue-200 text-blue-800'
              : saveStatus.type === 'success'
              ? 'bg-green-50 border-green-200 text-green-800'
              : 'bg-red-50 border-red-200 text-red-800 font-medium'
          }`}
        >
          <div className="flex items-center gap-3">
            {saveStatus.type === 'loading' && <div className="h-4 w-4 border-2 border-blue-600 border-t-transparent rounded-full animate-spin shrink-0" />}
            {saveStatus.type === 'success' && <CheckCircle2 className="h-5 w-5 text-green-600 shrink-0" />}
            {saveStatus.type === 'error' && <AlertCircle className="h-5 w-5 text-red-600 shrink-0" />}
            <span className="text-sm">{saveStatus.message}</span>
          </div>
          {saveStatus.type !== 'loading' && (
            <button
              onClick={() => setSaveStatus({ type: null, message: '' })}
              className="text-xs font-semibold underline hover:opacity-75 shrink-0 ml-4"
            >
              Tutup
            </button>
          )}
        </div>
      )}

      <SectionCard title="Pengaturan Konten Syarat & Ketentuan">
        <div className="space-y-4">
          <div>
            <Label required>Judul Dokumen</Label>
            <Input value={termsTitle} onChange={(e) => setTermsTitle(e.target.value)} />
          </div>
          <div>
            <Label>Subjudul / Deskripsi Singkat</Label>
            <Input value={termsSubtitle} onChange={(e) => setTermsSubtitle(e.target.value)} />
          </div>
          <div>
            <Label>Tanggal Terakhir Diperbarui</Label>
            <Input value={termsLastUpdated} onChange={(e) => setTermsLastUpdated(e.target.value)} placeholder="Contoh: 16 Juli 2026" />
          </div>
          <div>
            <Label>Paragraf Pengantar (Intro)</Label>
            <RichTextEditor
              minHeight={120}
              value={termsIntro}
              onChange={setTermsIntro}
            />
          </div>
          <div>
            <Label>Isi Ketentuan (Pasal & Aturan)</Label>
            <RichTextEditor
              minHeight={400}
              value={termsContent}
              onChange={setTermsContent}
            />
            <p className="mt-1 text-xs text-gray-500">
              Perubahan pada teks di atas akan langsung diperbarui pada halaman registrasi akun dan portal publik.
            </p>
          </div>
        </div>
      </SectionCard>
    </div>
  )
}
