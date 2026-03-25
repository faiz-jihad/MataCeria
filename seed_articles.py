from app.db.session import SessionLocal
from app.models import Article
import datetime

def seed_articles():
    db = SessionLocal()
    try:
        # 1. Hapus artikel lama
        print("Menghapus artikel lama...")
        db.query(Article).delete()
        
        # 2. Data artikel baru (Official Scraped Data)
        articles_data = [
            {
                "title": "7 Cara Menjaga Kesehatan Mata agar Tetap Sehat",
                "content": "Fungsi mata sangatlah penting bagi manusia. Penting untuk menjaga kesehatan mata agar terhindar dari berbagai masalah, mulai dari glaukoma hingga kebutaan. Langkahnya beragam, mulai dari mengonsumsi makanan bergizi seperti wortel dan bayam, hingga menghentikan kebiasaan lama yang merusak mata.\n\nSetiap orang dianjurkan memeriksakan mata secara rutin setidaknya 2 tahun sekali. Bagi orang dewasa di atas 40 tahun, disarankan setahun sekali untuk mencegah penyakit mata terkait usia.\n\nSelain itu, lindungi mata dari sinar UV dengan kacamata hitam dan kurangi durasi menatap layar gawai dengan aturan 20-20-20 (setiap 20 menit, lihat benda sejauh 6 meter selama 20 detik).",
                "image_url": "https://images.alodokter.com/dk0z4ums3/image/upload/v1643194017/attached_image/7-cara-menjaga-kesehatan-mata-alodokter.jpg",
                "share_url": "https://www.alodokter.com/tujuh-cara-menjaga-kesehatan-mata",
                "category": "Tips Kesehatan"
            },
            {
                "title": "Mengenal Gejala Rabun Jauh (Miopi) dan Penyebabnya",
                "content": "Rabun jauh atau miopi adalah kondisi mata yang menyebabkan objek jarak jauh terlihat kabur, sementara objek dekat tetap jelas. Gejala utamanya adalah kesulitan melihat papan tulis, rambu jalan, atau wajah orang dari kejauhan.\n\nGejala lainnya meliputi sering menyipitkan mata untuk memperjelas pandangan, mata terasa tegang atau lelah, dan sering mengalami sakit kepala. Pada anak-anak, gejala ini sering terlihat saat mereka duduk terlalu dekat dengan televisi atau sering mengucek mata.\n\nPenyebab utama miopi adalah bentuk bola mata yang terlalu panjang atau kornea yang terlalu melengkung, sehingga cahaya jatuh tidak tepat di retina. Faktor genetik dan kebiasaan menatap layar terlalu dekat juga berpengaruh besar.",
                "image_url": "https://images.alodokter.com/dk0z4ums3/image/upload/v1643194017/attached_image/gejala-miopia-alodokter.jpg",
                "share_url": "https://www.halodoc.com/artikel/ini-gejala-rabun-jauh-atau-miopi-yang-perlu-diketahui",
                "category": "Penyakit Mata"
            },
            {
                "title": "Menjaga Kesehatan Mata Anak di Era Digital",
                "content": "Di era digital, anak-anak sekolah dasar semakin sering terpapar layar gawai (gadget). Meskipun bermanfaat untuk belajar, paparan berlebihan dapat meningkatkan risiko gangguan mata seperti Computer Vision Syndrome (CVS).\n\nOrang tua perlu membatasi waktu layar (screen time) anak dan memastikan pencahayaan ruangan cukup saat anak menggunakan gawai. Dorong anak untuk bermain di luar ruangan karena paparan cahaya matahari alami dipercaya dapat menghambat perkembangan rabun jauh.\n\nKesehatan mata anak sangat berhubungan dengan prestasi belajar. Jika anak sering mengeluh pusing atau melihat buku terlalu dekat, segera konsultasikan ke dokter spesialis mata.",
                "image_url": "https://keslan.kemkes.go.id/storage/keslan/3710/image-thumbnail-1728377785.png",
                "share_url": "https://keslan.kemkes.go.id/view_artikel/3710/menjaga-kesehatan-mata-anak-sd-di-era-digital",
                "category": "Edukasi Anak"
            },
            {
                "title": "6 Jenis Makanan Kaya Vitamin untuk Mata",
                "content": "Nutrisi memainkan peran kunci dalam menjaga penglihatan tetap tajam. Selain wortel yang kaya vitamin A, sayuran hijau seperti bayam dan kangkung mengandung lutein dan zeaxanthin yang melindungi mata dari kerusakan sinar biru.\n\nIkan berlemak seperti salmon dan tuna mengandung asam lemak omega-3 yang membantu mencegah mata kering. Telur juga merupakan sumber nutrisi yang baik karena mengandung seng dan antioksidan.\n\nJangan lupakan buah-buahan sitrus (jeruk, lemon) yang kaya vitamin C untuk melawan risiko katarak. Pola makan seimbang adalah investasi jangka panjang untuk kualitas penglihatan Anda.",
                "image_url": "https://images.alodokter.com/dk0z4ums3/image/upload/v1643194017/attached_image/6-jenis-makanan-kaya-vitamin-untuk-mata-alodokter.jpg",
                "share_url": "https://www.alodokter.com/ini-daftar-makanan-yang-kaya-vitamin-untuk-mata",
                "category": "Nutrisi"
            },
            {
                "title": "Pentingnya Pemeriksaan Mata Rutin Sejak Dini",
                "content": "Banyak gangguan mata tidak menunjukkan gejala awal yang nyata. Pemeriksaan mata rutin bukan hanya untuk menentukan ukuran kacamata, tetapi juga untuk mendeteksi penyakit serius seperti glaukoma atau retinopati diabetik sejak tahap awal.\n\nPemeriksaan komprehensif oleh dokter mata mencakup tes ketajaman penglihatan, pemeriksaan tekanan bola mata, dan evaluasi saraf mata. Hal ini sangat krusial bagi mereka yang memiliki riwayat keluarga dengan penyakit mata.\n\nJangan menunggu pandangan kabur baru memeriksakan mata. Deteksi dini dapat menyelamatkan penglihatan Anda dari kerusakan permanen yang tidak bisa diperbaiki.",
                "image_url": "https://images.alodokter.com/dk0z4ums3/image/upload/v1643190800/attached_image/pentingnya-pemeriksaan-mata-rutin.jpg",
                "share_url": "https://www.halodoc.com/artikel/kapan-waktu-yang-tepat-untuk-periksa-mata",
                "category": "Edukasi"
            }
        ]
        
        # 3. Masukkan data
        print(f"Memasukkan {len(articles_data)} artikel baru...")
        for data in articles_data:
            new_article = Article(
                title=data["title"],
                content=data["content"],
                image_url=data["image_url"],
                share_url=data["share_url"],
                category=data["category"],
                created_at=datetime.datetime.utcnow()
            )
            db.add(new_article)
        
        db.commit()
        print("Seeding artikel berhasil!")
        
    except Exception as e:
        db.rollback()
        print(f"Error seeding articles: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_articles()
