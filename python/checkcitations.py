# Use this script to check if you have citations that don't exist in your
# .bib file or if there are entries in your .bib file that aren't cited
# in the text. Provide path to .tex file as first command line argument,
# path to .bib file as the second argument. 
# EG: python checkcitations.py main.tex mybib.bib
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
  badlabel_pat = re.compile(r"(\\label|\\ref|\\includegraphics)(\[[^]]*\])?\{([^}_]*_[^}_]*)\}")
  bib_entries = defaultdict(int) # Map bib keys to bib file line
  intext_citations = defaultdict(list) # Map citation keys to tex file lines
  intext_bad_labels = defaultdict(list) # Map citation keys to tex file lines

  with open(texfile, 'r') as f:
    for line in f:
      line_count += 1
      
      # Extract citation calls (\cite, \parencite, \textcite) from the line
      citation_args = cite_pat.findall(line)
      if len(citation_args) != 0: # If we found any citations
        for arg_tuple in citation_args:
          citations = arg_tuple[1].split(",") # Split up any multi citations
          for cite in citations:
            intext_citations[cite.strip()].append(line_count)
      
      # Check if there are any bad labels containing underscores,
      # which will cause misleading undefined citation errors
      bad_labels = badlabel_pat.findall(line)
      if len(bad_labels) != 0: 
        for label_tuple in bad_labels:
          bad_label = label_tuple[2]
          intext_bad_labels[bad_label].append(line_count)
      
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
  
  print(f" - bib file contains {len(bib_set)} references")
  print(f" - tex file contains {len(text_set)} unique citations")
  print(f" - tex file contains {len(intext_bad_labels)} bad labels")
  
  print("Here are the potential typos and the lines they happen on:")
  for typo in typos:
    print(f"\t{typo}: {intext_citations[typo]}")
  
  print("Here are the citations with entries but are not used:")
  for unused in bib_set.difference(text_set):
    print(f"\t{unused}: {bib_entries[unused]}")

  if len(intext_bad_labels) != 0:
    print("Undefined citation issues caused by these labels with underscores:")
    for k in intext_bad_labels:
      print(f"{k}: {intext_bad_labels[k]}")
