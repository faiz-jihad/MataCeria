from app.services.research_service import ResearchService

def test():
    print("=== Testing Research Service ===")
    
    queries = [
        "Apa ada penelitian terbaru tentang myopia?",
        "Bagaimana statistik WHO tentang gangguan penglihatan?",
        "Apakah ada alat laser mata baru yang disetujui FDA?",
        "Cari jurnal PubMed tentang astigmatism dan myopia."
    ]
    
    for q in queries:
        print(f"\nQUERY: {q}")
        context = ResearchService.get_research_context(q)
        if context:
            print(f"CONTEXT FOUND:\n{context}")
        else:
            print("NO CONTEXT FOUND.")

if __name__ == "__main__":
    test()
