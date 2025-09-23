#!/bin/bash
export GURU_COLOR=true
export GURU_VERBOSE=1
# cet connections
netstat -W --numeric-hosts | grep -e tcp -e udp | tr -s " " | cut -d " " -f5 |cut -d":" -f1 >iplist.log

# ip whitelist
#                            ujo.guru                    elisa    kaisanet github    canonical  AWS
cat iplist.log | grep -Ewv '192.168.100.10|192.168.100.1|193.229|62.145|185.199.1|91.189.91|51.21.' >ipwhite.log

# do whois
i=0
[[ -f whois.log ]] && rm whois.log
while read p; do
  ((i++))
  echo $i: $p $(whois $p | grep -m2 -e "Organization:" -e "descr:" -e "Country:" -e "org-name:" -e "Country:") >>whois.log
done <ipwhite.log

# organisation whitelist
grep -Ewv 'IANA|Google|Cloudflare|Stack Exchange|Fastly|Amazon|Facebook|Edgecast|Liquid Web|GitHub|Atlassian|Microsoft' whois.log >results.log

cat results.log | sed 's/Organization//g' | sed 's/Country//g' | sed 's/org-name//g' | sed 's/descr//g' | column -t -s':'

[[ -f iplist.log ]] && total=$(wc -l iplist.log |cut -d" " -f1)
[[ -f result.log ]] && non_witelisted=$(wc -l results.log |cut -d" " -f1)
[[ $total ]] || total=0
[[ $non_witelisted ]] || non_witelisted=0

# check those who did not found result
[[ -f noresult.log ]] && rm noresult.log
while read p; do
  [[ $(echo $p | cut -d" " -f3) ]] || echo $(echo $p | cut -d" " -f2) >>noresult.log
done <results.log
[[ -f noresult.log ]] && unknown=$(wc -l noresult.log |cut -d" " -f1)
[[ $unknown ]] || unknown=0

# print results
gr.msg -h "$i external connections where $non_witelisted non whitelisted, and $unknown unknown domains."

# check no results withh better tool
if [[ $unknown -gt 0 ]] ; then
  cat noresult.log | sed 's/Organization//g' | sed 's/Country//g' | sed 's/org-name//g' | sed 's/descr//g' | column -t -s':'
  if gr.ask "check $unknown results with no match?"; then
    while read p; do
      gr.msg -h "================ $p ================"
      whois -H $p || firefox --new-tab "https://www.whois.com/whois/$p"
    done <noresult.log
  fi
fi

# Printout all
if gr.ask "printout entire whois.log? $i item(s)"; then
  cat whois.log | sed 's/Organization//g' | sed 's/Country//g' | sed 's/org-name//g' | sed 's/descr//g' | column -t -s':'
fi
