import swalign
import os
import sys
import pandas as pd
import numpy as np

def get_homology(l,p,n=10):
    c1=list(g[:(p+l+n)])
    c1.reverse()
    c2=list(g[:(p+n)])
    c2.reverse()
    s=0
    reser=0
    for i,j in zip(c1,c2):
        if i==j:
            s+=1
            reser+=1
        elif reser<n:
            s=0
            reser+=1
        else:
            break
    return s

g="GGTGACGCTGCGAACGGACGTGAAGAATGTGCGAGACCCAGGGTCGGCGCCGCTGCGTTTCCCGGAACCACGCCCAGAGCAGCCGCGTCCCTGCGCAAACCCAGGGCTGCCTTGGAAAAGGCGCAACCCGGGCCCCCTCGAGCCGGCGCCAAAGTGGATCTCTGCTGTCCCTGTAATAAACCCGAAAATTTTGAATTTTTGTAATTTGTTTTTGTAATTCTTTAGTTTGTATGTCTGTTGCTATTA"
s=0

readId=[]

file_ = sys.argv[1]

indels=pd.DataFrame()
cut=int(sys.argv[2])
all_indels_data = []
with open(file_) as fp:
        
        while True:
            if s%100000==0:
                print(s)
            
            line = fp.readline()
            if s%4==0:
                r=line.split(" ")[0]
                #print(r)
            if s%4==1:
                c=line
                
                DF=999
                UF=999
                DF_r=999
                UF_r=999
                for i in range(0,60):
                    aux_c = g[(cut+i):(cut+i+10)]
                    read_pos=c.find(aux_c)
                    if read_pos!=-1:
                        if i>=4:
                            aux_r2 = g[(cut+i-4):(cut+i-1)]+g[(cut+i):(cut+i+10-4)]
                            read2 = c[:(read_pos-1)]+c[read_pos:]
                            if read2.find(aux_r2)!=-1:
                                for j in range(max(i-10,0),i):
                                    aux_r2 = g[(cut+j):(cut+i-1)]+g[(cut+i):(cut+j+10+1)]
                                    if read2.find(aux_r2)!=-1:
                                        DF_r=read2.find(aux_r2)
                                        DF=j
                                        break
                            else:
                                DF_r=read_pos
                                DF=i

                        else:
                            DF_r=read_pos
                            DF=i
                        break
                    if len(aux_c)!=10:
                        break
                for i in range(0,60):
                    aux_c = g[(cut-i-10):(cut-i)]
                    read_pos=c.find(aux_c)
                    if read_pos!=-1:
                        if i>=4:
                            aux_r2 = g[(cut-i-10+4):(cut-i)]+g[(cut-i+1):(cut-i+4+1)]
                            read2 = c[:(read_pos+10)]+c[read_pos+11:]
                            if read2.find(aux_r2)!=-1:
                                for j in range(max(i-10,0),i):
                                    aux_r2 = g[(cut-j-10):(cut-i)]+g[(cut-i+1):(cut-j+1)]
                                    if read2.find(aux_r2)!=-1:
                                        UF_r=read2.find(aux_r2)+10
                                        UF=-j
                                        break
                            else:
                                UF_r=read_pos+10
                                UF=-i
                        else:
                            UF_r=read_pos+10
                            UF=-i
                        break
                if (DF!=999) & (UF!=999) | (DF_r!=999) & (UF_r!=999):
                    readId.append(r)
                    types=[]
                    lens=[]
                    inserts=[]
                    poss=[]
                    homo=[]
                    if (DF==UF) & (DF_r!=UF_r):
                        lens.append(DF_r-UF_r)
                        inserts.append(c[UF_r:DF_r])
                        types.append("I")
                        poss.append(cut)
                        homo.append(0)
                    elif DF_r>UF_r:
                        types.append("I+D")
                        inserts.append(c[UF_r:DF_r])
                        lens.append(DF-UF)
                        poss.append(cut+UF)
                        homo.append(get_homology(DF-UF,cut+UF,n=10))
                    elif DF!=UF:
                        types.append("D")
                        inserts.append("")
                        lens.append(DF-UF+UF_r-DF_r)
                        poss.append(cut+UF)
                        homo.append(get_homology(DF-UF+UF_r-DF_r,cut+UF,n=10))
                    if len(types)!=0:
                        aux = pd.DataFrame({"Len":lens,"Type":types,"pos_R":poss,"Homology":homo,"Inserts":inserts})
                        aux["Name"]=r
                        aux["Pos"]=cut
                        all_indels_data.append(aux)
                
                    
            if not line:
                break
            
            s+=1
indels = pd.concat(all_indels_data, ignore_index=True)
indels.pos_R-=cut
final = pd.DataFrame({"Read":readId})
final.to_csv(file_+"_proc",sep="\t",index=None,header=None)

#indels["Condition"]=condition
indels.to_csv(file_+"_indel",sep="\t",index=None,header=None)