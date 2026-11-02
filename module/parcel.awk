# SPDX-FileCopyrightText: 2026 juanmacasado
# SPDX-License-Identifier: GPL-3.0-or-later
# Strict reader for the audited Android service CLI word format, not a generic
# Binder decoder. Unknown layouts fail closed. Inputs contain no writes.
function hex(s,    i,v,c) {
    v=0
    for (i=1;i<=length(s);i++) {
        c=index("0123456789abcdef",substr(s,i,1))-1
        if(c<0) return -1
        v=v*16+c
    }
    return v
}
function collect(line,    a,i,k) {
    sub(/'.*$/, "", line)
    k=split(line,a,/[[:space:]]+/)
    for(i=1;i<=k;i++) {
        if(a[i]=="" || a[i]==")") continue
        if(length(a[i])!=8 || a[i]!~/^[0-9a-fA-F]+$/) {bad=1;continue}
        words[++n]=tolower(a[i])
        if(n>256) {bad=1;exit 1}
    }
}
/^0x[0-9a-fA-F]+:/ {
    line=$0;address=$1;sub(/:$/, "",address);sub(/^0x/,"",address)
    if(hex(tolower(address))!=n*4) bad=1
    sub(/^0x[0-9a-fA-F]+:[[:space:]]*/,"",line);collect(line);next
}
/^Result: Parcel\(/ {
    header++
    line=$0;sub(/^Result: Parcel\([[:space:]]*/,"",line)
    if(line!="") collect(line)
    next
}
/^[[:space:]]*\)?[[:space:]]*$/ {next}
{bad=1}
END {
    if(bad || header!=1 || n<2 || words[1]!="00000000") exit 1
    if(operation=="version") {
        if(n!=2 || words[2]!="00000001") exit 1
        print 1;exit 0
    }
    if(operation=="hash") {
        if(n!=23 || words[2]!="00000028" || words[23]!="00000000") exit 1
        result=""
        for(i=3;i<=22;i++) {
            lo=hex(substr(words[i],5,4));hi=hex(substr(words[i],1,4))
            if(!((lo>=48&&lo<=57)||(lo>=97&&lo<=102)) ||
               !((hi>=48&&hi<=57)||(hi>=97&&hi<=102))) exit 1
            result=result sprintf("%c%c",lo,hi)
        }
        print result;exit 0
    }
    if(operation!="modes") exit 1
    count=hex(words[2])
    if(count!=4 && !(allow_five=="true" && count==5)) exit 1
    names[0]="00690056 00690076 00000064"
    names[1]="0061004e 00750074 00610072 0000006c"
    names[2]="00690043 0065006e 0061006d 00690074 00000063"
    names[3]="00720042 006c0069 0069006c 006e0061 00000074"
    names[4]="00690057 00650064 00410020 004f004d 0045004c 00200044 00610047 0075006d 00000074"
    lengths[0]=5;lengths[1]=7;lengths[2]=9;lengths[3]=9;lengths[4]=17
    p=3
    for(id=0;id<count;id++) {
        if(words[p]!="00000001") exit 1
        size=hex(words[p+1]);k=split(names[id],expected," ")
        if(size!=(3+k)*4 || hex(words[p+2])!=id || hex(words[p+3])!=lengths[id]) exit 1
        for(j=1;j<=k;j++) if(words[p+3+j]!=expected[j]) exit 1
        p=p+1+size/4
    }
    if(p!=n+1) exit 1
    print count
}
