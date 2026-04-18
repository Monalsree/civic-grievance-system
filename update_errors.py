import os
import glob

auth_dir = r"d:\civic-grievance-system\mobile appppp\lib\screens\auth"
files = glob.glob(os.path.join(auth_dir, "*.dart"))

# We are searching for the `if (_errorMessage != null)` block and replacing the whole container.
# Notice that indentation might vary (like in citizen_login vs admin_register), but we can just regex it.

import re

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Use regex to find the Error message block
    # It starts with \s+if (_errorMessage != null)
    # and ends with the first closing parenthesis of the Container.
    
    pattern = r"""(\s*if \(_errorMessage != null\)\s+Container\([\s\S]*?child: Text\([\s\S]*?_errorMessage!,[\s\S]*?style: const TextStyle\([\s\S]*?color:.*?,\s*fontSize:.*?,[\s\S]*?\),[\s\S]*?\),[\s\S]*?\),)"""
    
    # We will replace it with a clean, readable alert box.
    # The new box will have a white text, and a light red background (alpha=0.15), with a strong red border.
    
    def replacer(match):
        indent = match.group(1).split('if')[0]
        new_block = f"""{indent}if (_errorMessage != null)
{indent}  Container(
{indent}    width: double.infinity,
{indent}    decoration: BoxDecoration(
{indent}      color: const Color(0xFFfee2e2), // Very light red background
{indent}      borderRadius: BorderRadius.circular(12),
{indent}      border: Border.all(
{indent}        color: const Color(0xFFef4444), // Strong red border
{indent}        width: 1.5,
{indent}      ),
{indent}    ),
{indent}    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
{indent}    margin: const EdgeInsets.only(bottom: 20),
{indent}    child: Row(
{indent}      crossAxisAlignment: CrossAxisAlignment.center,
{indent}      children: [
{indent}        const Icon(Icons.error_outline, color: Color(0xFFef4444), size: 24),
{indent}        const SizedBox(width: 12),
{indent}        Expanded(
{indent}          child: Text(
{indent}            _errorMessage!,
{indent}            style: const TextStyle(
{indent}              color: Color(0xFF991b1b), // Dark red text
{indent}              fontSize: 14,
{indent}              fontWeight: FontWeight.w500,
{indent}            ),
{indent}          ),
{indent}        ),
{indent}      ],
{indent}    ),
{indent}  ),"""
        return new_block
    
    new_content = re.sub(pattern, replacer, content)
    
    if new_content != content:
        with open(f, 'w', encoding='utf-8') as file:
            file.write(new_content)
            
print("Error messages styled!")