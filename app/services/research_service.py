import requests
import logging

logger = logging.getLogger(__name__)

class ResearchService:
    @staticmethod
    def fetch_clinical_trials(condition: str = "myopia", limit: int = 3):
        """Fetch studies from ClinicalTrials.gov"""
        url = f"https://clinicaltrials.gov/api/v2/studies?query.cond={condition}&pageSize={limit}&format=json"
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                studies = data.get("studies", [])
                results = []
                for s in studies:
                    protocol = s.get("protocolSection", {})
                    id_info = protocol.get("identificationModule", {})
                    status_info = protocol.get("statusModule", {})
                    title = id_info.get("briefTitle", "No Title")
                    status = status_info.get("overallStatus", "Unknown")
                    results.append(f"[Trial] {title} (Status: {status})")
                return "\n".join(results)
        except Exception as e:
            logger.error(f"Error fetching ClinicalTrials: {e}")
        return ""

    @staticmethod
    def fetch_who_stats():
        """Fetch WHO statistics on refractive errors"""
        url = "https://ghoapi.azureedge.net/api/Indicator?$filter=contains(IndicatorName,%20'refractive')"
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                values = data.get("value", [])
                if values:
                    # Ambil 2 indikator pertama agar tidak kepanjangan
                    results = [f"[WHO] {v.get('IndicatorName')}" for v in values[:2]]
                    return "\n".join(results)
        except Exception as e:
            logger.error(f"Error fetching WHO GHO: {e}")
        return ""

    @staticmethod
    def fetch_fda_devices(query: str = "myopia", limit: int = 3):
        """Fetch medical device approvals from OpenFDA"""
        url = f"https://api.fda.gov/device/510k.json?search=device_name:\"{query}\"&limit={limit}"
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                results = data.get("results", [])
                formatted = []
                for r in results:
                    name = r.get("device_name", "Unknown Device")
                    applicant = r.get("applicant", "Unknown Applicant")
                    date = r.get("decision_date", "N/A")
                    formatted.append(f"[FDA] {name} by {applicant} (Approved: {date})")
                return "\n".join(formatted)
        except Exception as e:
            logger.error(f"Error fetching OpenFDA: {e}")
        return ""

    @staticmethod
    def fetch_pubmed_journals(term: str = "myopia AND astigmatism", limit: int = 3):
        """Fetch recent journals from PubMed"""
        # Step 1: Search for IDs
        search_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term={term}&retmode=json&retmax={limit}"
        try:
            res_search = requests.get(search_url, timeout=10)
            if res_search.status_code == 200:
                ids = res_search.json().get("esearchresult", {}).get("idlist", [])
                if not ids:
                    return ""
                
                # Step 2: Fetch Summary for those IDs
                summary_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id={','.join(ids)}&retmode=json"
                res_summary = requests.get(summary_url, timeout=10)
                if res_summary.status_code == 200:
                    sum_data = res_summary.json().get("result", {})
                    results = []
                    for uid in ids:
                        article = sum_data.get(uid, {})
                        title = article.get("title", "No Title")
                        pub_date = article.get("pubdate", "N/A")
                        results.append(f"[PubMed] {title} ({pub_date})")
                    return "\n".join(results)
        except Exception as e:
            logger.error(f"Error fetching PubMed: {e}")
        return ""

    @classmethod
    def get_research_context(cls, query: str):
        """Generate a combined context from all research APIs based on user query"""
        context_parts = []
        
        # Heuristic simple detection
        q_lower = query.lower()
        
        # 1. Clinical Trials
        if any(w in q_lower for w in ["penelitian", "studi", "uji", "clinical", "trial", "obat", "tetes"]):
            trials = cls.fetch_clinical_trials("myopia")
            if trials: context_parts.append(f"Uji Klinis Terbaru:\n{trials}")
            
        # 2. WHO Stats
        if any(w in q_lower for w in ["statistik", "data", "who", "berapa", "jumlah", "prevalensi"]):
            who = cls.fetch_who_stats()
            if who: context_parts.append(f"Statistik Kesehatan (WHO):\n{who}")
            
        # 3. OpenFDA
        if any(w in q_lower for w in ["alat", "laser", "lensa", "kacamata", "fda", "izin"]):
            fda = cls.fetch_fda_devices("myopia")
            if fda: context_parts.append(f"Persetujuan Alat Medis (FDA):\n{fda}")
            
        # 4. PubMed Journals
        if any(w in q_lower for w in ["jurnal", "artikel", "ilmiah", "pubmed", "studi", "riset"]):
            journals = cls.fetch_pubmed_journals("myopia")
            if journals: context_parts.append(f"Jurnal Medis Terbaru (PubMed):\n{journals}")
            
        return "\n\n".join(context_parts) if context_parts else ""
