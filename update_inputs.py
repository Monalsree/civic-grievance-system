import os
import glob

auth_dir = r"d:\civic-grievance-system\mobile appppp\lib\screens\auth"
files = glob.glob(os.path.join(auth_dir, "*.dart"))

old_input_bg = """                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1f3a),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 51),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField("""

new_input_bg = """                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField("""

old_input_bg2 = """      decoration: BoxDecoration(
        color: const Color(0xFF1a1f3a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 51),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField("""

new_input_bg2 = """      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField("""

old_text_style = "style: const TextStyle(color: Colors.white, fontSize: 16),"
new_text_style = "style: const TextStyle(color: Colors.black, fontSize: 16),"

old_back_btn = """                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 25),
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),"""

new_back_btn = """                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),"""

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    content = content.replace(old_input_bg, new_input_bg)
    content = content.replace(old_input_bg2, new_input_bg2)
    content = content.replace(old_text_style, new_text_style)
    content = content.replace(old_back_btn, new_back_btn)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

print("Applied UI fixes across all auth screens.")
