def score(lead_desc, profile_skills=['PSCAD','CAISO','NERC'], profile_loc='Oakland/remote'):
    score = 0
    skills_match = sum(1 for s in profile_skills if s.lower() in lead_desc.lower())
    score += skills_match * 3  # Max 12
    loc_match = 1 if any(l in lead_desc.lower() for l in ['oakland','pg&e','caiso']) else 0
    score += loc_match * 4
    salary_match = 2 if 'senior' in lead_desc.lower() or '$' in lead_desc else 0
    score += salary_match * 2
    return min(score, 10)

# Example
print(score('PG&E grid engineer Oakland PSCAD'))  # ~9