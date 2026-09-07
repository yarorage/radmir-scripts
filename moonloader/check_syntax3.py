with open(r'C:\Games\RADMIR Games\RADMIR CRMP\moonloader\AutoLoginByYaroRage\utils.lua', 'r', encoding='utf-8') as f:
    content = f.read()

open_braces = 0
close_braces = 0
open_parens = 0
close_parens = 0
open_brackets = 0
close_brackets = 0

for i, char in enumerate(content):
    if char == '{':
        open_braces += 1
    elif char == '}':
        close_braces += 1
    elif char == '(':
        open_parens += 1
    elif char == ')':
        close_parens += 1
    elif char == '[':
        open_brackets += 1
    elif char == ']':
        close_brackets += 1

print('Braces: {} open, {} close'.format(open_braces, close_braces))
print('Parens: {} open, {} close'.format(open_parens, close_parens))
print('Brackets: {} open, {} close'.format(open_brackets, close_brackets))

lines = content.split('\n')
for i, line in enumerate(lines):
    single_quotes = line.count("'")
    double_quotes = line.count('"')
    if single_quotes % 2 != 0:
        print('Unclosed single quote at line {}: {}'.format(i+1, line[:80]))
    if double_quotes % 2 != 0:
        print('Unclosed double quote at line {}: {}'.format(i+1, line[:80]))

print('Basic syntax check done')