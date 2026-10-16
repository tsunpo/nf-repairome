import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os
import shutil
import seaborn as sns
import sys
import dask.dataframe as dd
import sys


def convert_columns(x):
    x=x.split("_")
    if float(x[0])>0:
        x[0]=0
    if len(x)==3:
        x.append("")
    return "Del "+str(int(float(x[0])*-1))+";H "+str(int(float(x[1])))+";Ins "+x[3]+";Pos "+str(int(float(x[2])))


all_counts=pd.DataFrame()
all_data_guide=pd.DataFrame()
all_ids=pd.DataFrame()
ruta=""

files= sys.argv[1].split(",")
name=sys.argv[2]
print(files)

for read in files:
    print(read)
    sys.stdout.flush()
    ids = dd.read_csv(read+"_guides.txt",header=None,sep="\t").compute()
    print("Number of guides: "+str(ids.shape[0]))
    ids = ids[ids[1]!="*"]
    ids[0]="@"+ids[0]
    ids = ids.set_index(0) 
    
    reads_al = dd.read_csv(ruta+read+"_proc",header=None,sep="\t").compute()
    reads_al.columns = ["read"]#["read","cigar","q","n_del","Ppos_read"]
    reads_al["q"]=0

    ids=ids.merge(reads_al,left_on=0,right_on="read")
    del reads_al
    ids[0] = ids["key_0"]
    del ids["key_0"]
    ids = ids.set_index(0) 
    #all_ids=pd.concat([all_ids,ids]).reset_index(drop=True)
    
    sys.stdout.flush()
    indels = dd.read_csv(ruta+read+"_indel",header=None,sep="\t").compute() 
    print("Number of indels: "+str(indels.shape[0]))
    indels.columns =  ["Len","Type","pos","Homology","Inserts","read","P"]
    indels.loc[(indels.Type=="D") | (indels.Type=="I+D") ,"Len"]=indels.loc[(indels.Type=="D") | (indels.Type=="I+D"),"Len"]*-1
    indels["Microhomology_repair"] = indels.Homology>1

    all_data_guide_aux = indels.merge(ids,left_on="read",right_on="read",how="right")
    print("Merged: "+str(all_data_guide_aux.shape[0]))
    all_data_guide_aux.Type=all_data_guide_aux.Type.fillna("No indel")

    

    all_data_guide_aux["Homology"]=all_data_guide_aux.Homology.astype(str)


    counts=ids.groupby([1]).q.count().reset_index()
    counts.columns=["guide","n_total"]

    counts_del = all_data_guide_aux[(all_data_guide_aux.Type=="No indel")]
    counts_del = counts_del.groupby([1]).q.count().reset_index()
    counts_del.columns=["guide","n_notEdited"]
    all_counts_aux=counts.merge(counts_del)

    all_counts=pd.concat([all_counts,all_counts_aux]).reset_index(drop=True)
    all_counts=all_counts.groupby("guide").sum().reset_index()


    del ids
    
    all_data_guide_aux=all_data_guide_aux[all_data_guide_aux.Type!="No indel"]
    all_data_guide_aux["guide"]=all_data_guide_aux[1]
    all_data_guide_aux[['Inserts']] = all_data_guide_aux[['Inserts']].fillna(value="")
    all_data_guide_aux["Event2"] = all_data_guide_aux.Len.astype(str)+"_"+all_data_guide_aux.Homology.astype(str)+"_"+all_data_guide_aux.pos.astype(str)+"_"+all_data_guide_aux.Inserts.astype(str)

    #pd.DataFrame(all_data_guide_aux.Event2.value_counts()).to_csv("values_inserts_"+read)
    all_data_guide_aux["v"]=0
    all_data_guide_aux=all_data_guide_aux.groupby(["guide","Event2"]).count().reset_index()
    all_data_guide_aux=all_data_guide_aux[["guide","Event2","v"]]
    all_data_guide=pd.concat([all_data_guide,all_data_guide_aux]).reset_index(drop=True)
    all_data_guide=all_data_guide.groupby(["guide","Event2"]).v.sum().reset_index()

    #all_data_guide_aux.to_csv("all_data_"+read,index=None)
    del all_data_guide_aux

    print("")
    #


all_counts["Protein"] = [i.split("_")[1] for i in all_counts["guide"]]
all_counts.to_csv("counts_"+name+".csv",index=None)


all_data_guide["Protein"] = [i.split("_")[1] for i in all_data_guide["guide"]]
a=all_data_guide.groupby("Protein").Event2.value_counts()
a = a.index[a>3].get_level_values(1).tolist()
all_data_guide=all_data_guide.loc[all_data_guide.Event2.isin(a),:]
final_matrix = all_data_guide.pivot_table(index=["Protein","guide"], columns=['Event2'],values="v" ,aggfunc="sum").fillna(0)
final_matrix.columns=[convert_columns(i) for i in final_matrix.columns]


final_matrix=final_matrix.reset_index()
final_matrix.to_csv("profiles_"+name+".csv",index=None)


