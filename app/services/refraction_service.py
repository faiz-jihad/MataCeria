import math
import logging

logger = logging.getLogger(__name__)

class RefractionService:
    # Mapping Row to Snellen Denominator (20/x)
    SNELLEN_MAPPING = {
        1: 200,
        2: 100,
        3: 70,
        4: 50,
        5: 40,
        6: 30,
        7: 25,
        8: 20
    }

    MISSED_CHARS_THRESHOLD = 2

    @staticmethod
    def calculate_physical_size_mm(px: int, ppi: float) -> float:
        """
        Convert pixels to physical millimeters using PPI.
        """
        if ppi <= 0:
            return 0.0
        inches = px / ppi
        mm = inches * 25.4
        return mm

    @classmethod
    def calculate_acuity(cls, smallest_row: int, missed_chars: int) -> tuple[str, float]:
        """
        Calculate Snellen fraction and decimal acuity.
        Adjusts row based on missed characters.
        """
        adjusted_row = smallest_row

        # Adjust score if missed too many chars
        if missed_chars > cls.MISSED_CHARS_THRESHOLD:
            adjusted_row -= 1

        # Keep row within valid bounds 1 to 8
        if adjusted_row < 1:
            adjusted_row = 1
        elif adjusted_row > 8:
            adjusted_row = 8

        denominator = cls.SNELLEN_MAPPING[adjusted_row]
        snellen_fraction = f"20/{denominator}"
        decimal_acuity = 20.0 / denominator

        return snellen_fraction, decimal_acuity

    @staticmethod
    def classify_vision(decimal_acuity: float) -> tuple[str, str]:
        """
        Classify visual acuity and return category and recommendation.
        """
        if decimal_acuity >= 1.0:
            return "Normal Vision", "Maintain eye health (20-20-20 rule)"
        elif 0.5 <= decimal_acuity < 1.0:
            return "Mild Impairment", "Consider eye check"
        else:
            return "Visual Impairment", "Consult ophthalmologist"

    @classmethod
    def process_screening(cls, raw_data, device_info, test_type: str = "distance_vision") -> dict:
        """
        Process the entire screening test data and generate result.
        Supports Distance Vision (Miopia) and Near Vision (Hypermetropia/Presbyopia).
        """
        screen_width_mm = cls.calculate_physical_size_mm(device_info.screen_width_px, device_info.screen_ppi)
        logger.info(f"Screen physical width validated: {screen_width_mm:.2f} mm")

        # Acuity calculation
        snellen_fraction, decimal_acuity = cls.calculate_acuity(
            smallest_row=raw_data.smallest_row_read,
            missed_chars=raw_data.missed_chars
        )

        # Baseline Classification
        category, base_recommendation = cls.classify_vision(decimal_acuity)
        
        # Multi-Condition Logic
        condition = "Normal"
        is_cylinder = getattr(raw_data, 'astigmatism_found', False)
        
        if decimal_acuity < 1.0:
            if test_type == "near_vision":
                condition = "Hipermetropia / Presbiopia"
            else:
                condition = "Miopia (Rabun Jauh)"
        
        if is_cylinder:
            if condition == "Normal":
                condition = "Astigmatisme (Silinder)"
            else:
                condition += " & Astigmatisme"

        # Refined Recommendation
        recommendation = base_recommendation
        if condition != "Normal":
            if test_type == "near_vision":
                recommendation = "Gunakan kacamata baca atau konsultasikan untuk koreksi rabun dekat."
            elif is_cylinder:
                recommendation = "Disarankan tes refraksi lengkap untuk menentukan derajat silinder (Axis)."

        return {
            "visual_acuity": snellen_fraction,
            "snellen_decimal": round(decimal_acuity, 2),
            "category": category,
            "condition_category": condition,
            "is_cylinder": is_cylinder,
            "recommendation": recommendation
        }
