import re
from collections import defaultdict
import sys

if __name__ == "__main__":
  texfile = sys.argv[1]
  if len(sys.argv) == 3:
    bibfile = sys.argv[2]
  else:
    bibfile = "ex_" + texfile
    
  line_count = 0
  example_num = 0
  
  bib_pat = re.compile(r"@[^{]+{([^,]+)")
  cite_pat = re.compile(r"\\(cite|parencite|textcite)\{([^}]+)\}")
    
  bib_entries = defaultdict(int)
  intext_citations = defaultdict(list) # Map example strings to their example index
  
  with open(texfile, 'r') as f:
    for line in f:
      line_count += 1
      
      # Extract however many citations there are in the command, split on the ,
      citation_args = cite_pat.findall(line)
      
      if len(citation_args) != 0:
        for arg_tuple in citation_args:
          citations = arg_tuple[1].split(",")
          for cite in citations:
            intext_citations[cite.strip()].append(line_count)
  
  line_count = 0
  
  with open(bibfile, 'r',encoding='utf8') as f:
    for line in f:
      line_count += 1
      
      # Extract however many citations there are in the command, split on the ,
      entry = bib_pat.findall(line)
      if len(entry) == 1:
        bib_entries[entry[0]] = line_count

  bib_set = {entry for entry in bib_entries.keys()}
  text_set = {entry for entry in intext_citations.keys()}
  typos = text_set.difference(bib_set)
  
  print("Here are the potential typos and the lines they happen on:")
  for typo in typos:
    print(f"\t{typo}: {intext_citations[typo]}")
  
  print("Here are the citations with entries but are not used:")
  for unused in bib_set.difference(text_set):
    print(f"\t{unused}: {bib_entries[unused]}")
