#!/usr/bin/python

idx = 0
f_out = None

with open("README.md",'r',encoding="utf-8") as f:
    for line in f.readlines():
        if line.startswith("```mermaid"):
            idx += 1
            f_out = open(f"{idx}.mmd",'w',encoding='utf-8')
            continue
        elif line.startswith("```"):
            f_out = None
        if f_out:
            f_out.write(line)

