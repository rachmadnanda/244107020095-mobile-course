# Refleksi Teknis

## Mengapa UI tidak memanggil Dio langsung?

UI seharusnya mengatur tampilan dan interaksi, bukan detail HTTP, parsing JSON, timeout, atau pemetaan error. Jika UI memanggil Dio langsung, kode menjadi berulang, sulit diuji tanpa jaringan, dan perubahan endpoint menyebar ke banyak widget. Repository memberi satu batas yang jelas untuk data dan error.

## Kapan pagination client-side cukup?

Client-side pagination cukup ketika seluruh dataset kecil sudah tersedia, misalnya daftar lokal yang sudah diambil sekali. Untuk posts yang terus bertambah atau berukuran besar, pagination server lebih tepat karena hanya mengirim subset data. Implementasi ini memakai `_page` dan `_limit` agar biaya transfer dan penggunaan memori tetap terbatas.

## Bagaimana exception menjadi AsyncError?

`AsyncNotifier.build` mengembalikan Future dari repository. Riverpod menangkap exception Future tersebut dan mengubahnya menjadi `AsyncError`, sehingga widget cukup membaca `AsyncValue` tanpa try/catch di setiap halaman. Try/catch eksplisit tetap diperlukan ketika UI perlu retry manual, menggabungkan data halaman berikutnya, atau mempertahankan data lama saat request lanjutan gagal.

## Bagian AI yang diperbaiki

Hasil awal AI untuk pagination belum memiliki state loading awal dan menghasilkan fragmen `ListView.builder` yang tidak valid. Saya memperbaiki state menjadi eksplisit (`isLoading`, `isLoadingMore`, `hasMore`), membersihkan widget builder, dan menambahkan empty state. Keputusan ini dipilih agar empat state yang diminta dapat dibedakan dengan jelas dan analyzer dapat memverifikasi source sebelum aplikasi dijalankan.

Guard `isLoadingMore` dipertahankan agar event scroll yang datang berulang tidak membuat request halaman yang sama secara paralel.
