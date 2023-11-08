/*       1         2         3         4         5         6         7         8
********************************************************************************
  Oracle Script Name:  transactions_table.sql
  Created by        :  Bijay Paudyal [Economist Intern] and Shawn Stoddard
                       [Senior Resource Economist]
  Created on        :  Nov 1, 2023  
  Abstract          :  Build a view for transaction table.
                       Rate_class* has not been finalized in this table
                       

*******************************************************************************/


/*******************************************************************************
Tables used: 
      Blkuse----
            enquestacis.ciconsumptionhistblock --aggregating data by block
                    consumptionhistid
                    readsequence
      Blkuse_header----   
            enquestacis.ciconsumptionhist
                    accountnumber  
                    consumptionhistid           
                    readsequence
                    device
      wacm----
              cis.fwacmas
              wacm_cust       --customer number
              wacm_premise_no --premiseid
      blkuse_final---- blkuse_header join on blkuse and wacm
              premiseid 
      cteBillableItems----                                
              CIS.fcihistv join
              enquesta.cibillableitem
              CIS.fcihistv
     cteTotalUsage----                      
              ENQUESTACIS.CICONSUMPTIONHIST             
              enquesta.wawatercustomermaster             
              cis.fciregister
     cteCombinedData---- 
              CIS.FCIHISTF
              enquesta.wawatercustomermaster            
              cteBillableItems
              cteTotalUsage
              
     rate_class---
              enquestacis.ciratekind
              enquestacis.ciratedetail
              enquestacis.ciitemratedetail
              enquestacis.ciitemcode
              enquestacis.cisteprate
              
              
                           
*******************************************************************************/


with 


 date_range as
 (select 20210301 as startdte, 20210331 as enddte from dual),
  /* creating block use data */
 blkuse as --aggregate consumption data by block 
(
select  c2.consumptionhistid 
       ,c2.readsequence 
       ,sum(case when c2.blocknumber = 1 then c2.blockusage else null end) as blkuse_1
       ,sum(case when c2.blocknumber = 2 then c2.blockusage else null end) as blkuse_2
       ,sum(case when c2.blocknumber = 3 then c2.blockusage else null end) as blkuse_3
       ,sum(case when c2.blocknumber = 4 then c2.blockusage else null end) as blkuse_4
       ,sum(case when c2.blocknumber = 5 then c2.blockusage else null end) as blkuse_5
       ,sum(case when c2.blocknumber = 1 then c2.blockamount else null end) as blkamt_1
       ,sum(case when c2.blocknumber = 2 then c2.blockamount else null end) as blkamt_2
       ,sum(case when c2.blocknumber = 3 then c2.blockamount else null end) as blkamt_3
       ,sum(case when c2.blocknumber = 4 then c2.blockamount else null end) as blkamt_4
       ,sum(case when c2.blocknumber = 5 then c2.blockamount else null end) as blkamt_5
       ,sum(case when c2.blocknumber = 1 then c2.blockrate else null end) as blkrate_1
       ,sum(case when c2.blocknumber = 2 then c2.blockrate else null end) as blkrate_2
       ,sum(case when c2.blocknumber = 3 then c2.blockrate else null end) as blkrate_3
       ,sum(case when c2.blocknumber = 4 then c2.blockrate else null end) as blkrate_4
       ,sum(case when c2.blocknumber = 5 then c2.blockrate else null end) as blkrate_5
from enquestacis.ciconsumptionhistblock c2 
group by  c2.consumptionhistid, c2.readsequence
),


--creating a rate class table 
rate_class as
(
select r1.ratekindid
      ,r2.description AS rkind_desc
      --Using case to define utility type 
      ,CASE
         WHEN r1.ratekindid = 0 AND r1.rate BETWEEN 1 AND 2500 THEN
          'W'   -- water service
         WHEN r1.ratekindid = 0 AND r1.rate = 2502 THEN
          'D'  --- item driver ditch on-off
         WHEN r1.ratekindid = 2 AND
              (r1.rate BETWEEN 1 AND 19 OR r1.rate = 100) THEN
          'U'   -- multi unit flat
         WHEN r1.ratekindid = 2 AND
              (r1.rate BETWEEN 20 AND 31 OR r1.rate BETWEEN 110 AND 116 OR
              r1.rate BETWEEN 210 AND 260) THEN
          'F'   --- fire
         WHEN r1.ratekindid = 2 AND r1.rate IN (40, 41) THEN
          'D'   --- ditch irrigation
         WHEN r1.ratekindid = 2 AND r1.rate = 50 THEN
          'B'  --- backflow 
       END AS utl_typ
      ,r1.rate
      ,r1.description AS ratedesc
      ,nvl(r3.billingdescription, r4.comments) AS bill_desc
      ,nvl(r5.description, r9.description) AS bill_desc_short
      , /* Use a case to define rate schedule codes */
       /* Outer case is utility type then rate schedule */
       CASE
         WHEN r1.ratekindid = 0 AND r1.rate BETWEEN 1 AND 2500 THEN
         /* Utility type W for metered services */
          (CASE
            WHEN r1.rate = 1  THEN  'RMWS'
            WHEN r1.rate = 10 THEN  'MMWS'
            WHEN r1.rate = 20 THEN  'GMW75'
            WHEN r1.rate = 21 THEN  'GMW01'
            WHEN r1.rate = 22 THEN  'GMW15'
            WHEN r1.rate = 23 THEN  'GMW02'
            WHEN r1.rate = 24 THEN  'GMW03'
            WHEN r1.rate = 25 THEN  'GMW04'
            WHEN r1.rate = 26 THEN  'GMW06'
            WHEN r1.rate = 27 THEN  'GMW08'
            WHEN r1.rate = 28 THEN  'GMW10'
            WHEN r1.rate = 30 THEN  'MIS'
            WHEN r1.rate = 40 THEN  'NPSU'
            WHEN r1.rate = 41 THEN  'NPST'
            WHEN r1.rate = 50 THEN  'IWS'
            WHEN r1.rate = 51 THEN  'IWSU'
            WHEN r1.rate = 52 THEN  'IWST'
            WHEN r1.rate = 60 THEN  'LVS'
            WHEN r1.rate = 70 THEN  'FSRP'
            WHEN r1.rate = 100 THEN  'RMWG'
            WHEN r1.rate = 110 THEN  'GOVS'
            WHEN r1.rate = 111 THEN  'GOVL'
            WHEN r1.rate = 112 THEN  'COMS'
            WHEN r1.rate = 113 THEN  'COML'
            WHEN r1.rate = 120 THEN  'MISG'
            WHEN r1.rate = 200 THEN  'RMWD1'
            WHEN r1.rate = 201 THEN  'RMWD2'
            WHEN r1.rate = 202 THEN  'MMWD'
            WHEN r1.rate = 203 THEN  'GMWD'
            WHEN r1.rate = 204 THEN  'MISD'
            WHEN r1.rate = 210 THEN  'FPSD-DU'
            WHEN r1.rate = 900 THEN  'NO BILL'
            WHEN r1.rate = 2500 THEN  'ITEM DRIVER'
            ELSE
             NULL
          END /* End case utility type W */
          )
       /* When utility type = U */
         WHEN r1.ratekindid = 2 AND
              (r1.rate BETWEEN 1 AND 19 OR r1.rate = 100) THEN
          (CASE
            WHEN r1.rate = 1 THEN  'SUFR'
            WHEN r1.rate BETWEEN 2  AND  9 THEN  'MRFS'
            WHEN r1.rate BETWEEN 10 AND 19 THEN  'MRIS'
            WHEN r1.rate = 100 THEN  'RFWG'
          END /* end of utility type U */
          )
       /* When Utility type = F */
         WHEN r1.ratekindid = 2 AND
              (r1.rate BETWEEN 20 AND 31 OR r1.rate BETWEEN 110 AND 116 OR
              r1.rate BETWEEN 210 AND 260) THEN
          (CASE
            WHEN r1.rate BETWEEN 20 AND 31 THEN   'FPST'
            WHEN r1.rate BETWEEN 110 AND 116 THEN 'FPSG'
            WHEN r1.rate BETWEEN 210 AND 260 THEN 'FPSD'
          END /* end of utility type F */
          )
       /* When Utility type = D or B */
         WHEN r1.ratekindid = 2 AND r1.rate IN (40, 41, 50) THEN
          (CASE
            WHEN r1.rate IN (40, 41) THEN  'DITCH'
            WHEN r1.rate = 50 THEN 'Backflow'
          END /* of utility types D or B */
          )
         ELSE
          NULL
       END /* End outer case for utility type */ AS rsch

  FROM enquestacis.ciratemaster r1
  LEFT OUTER JOIN enquestacis.ciratekind r2
    ON r1.ratekindid = r2.ratekindid
  LEFT OUTER JOIN enquestacis.ciratedetail r3
    ON r1.ratemasterid = r3.ratemasterid
   AND r3.ratedetailid IN
       (SELECT b.ratedetailid
          FROM (SELECT a.ratedetailid
                      ,a.effectivedate
                      ,MAX(a.effectivedate) over(PARTITION BY a.ratemasterid) AS last_date
                  FROM enquestacis.ciratedetail a) b
         WHERE b.effectivedate = b.last_date)
  LEFT OUTER JOIN enquestacis.ciitemratedetail r4
    ON r3.ratedetailid = r4.ratedetailid
  LEFT OUTER JOIN enquestacis.ciitemcode r5
    ON r4.itemcode = r5.itemcode
   AND r1.application = r5.application

  LEFT OUTER JOIN enquestacis.cisteprate r9
    ON r1.application = r9.application
   AND r3.steprateid = r9.steprateid

 where r1.application = 3
 order by r1.ratekindid, r1.rate
),


--generating cte filtering data with transactioncode 102
blkuse_header as  
(
select  c1.accountnumber
       ,c1.consumptionhistid
       ,c1.readsequence 
       ,c1.device
       ,TO_NUMBER(TO_CHAR(c1.billdate, 'YYYYMMDD')) AS billdate
       ,c1.hasblocks
       ,c1.numberofdays
       ,TO_NUMBER(TO_CHAR(c1.fromdate, 'YYYYMMDD')) AS fromdate
       ,TO_NUMBER(TO_CHAR(c1.todate, 'YYYYMMDD')) AS todate
       ,c1.rate1
       ,c1.ratekind1
       ,c1.servicenumbersequence
       ,c1.transactioncode
  from enquestacis.ciconsumptionhist c1
  where c1.transactioncode = 102
),


wacm as  -- generating to link account number to premise number
(
select  f1.wacm_cust -- account number
       ,f1.wacm_address_seq_no
       ,f1.wacm_occupant_cis_no
       ,f1.wacm_premise_no as premiseid
       ,f1.wacm_ref_acct
       ,f1.wacm_no_units
  from cis.fwacmas f1
 ),

/* finalizing block use data extract */
blkuse_final as 
(
 select b3.premiseid     
       ,b1.accountnumber -- joining with wacm_cust
       ,b3.wacm_address_seq_no
       ,b1.servicenumbersequence
       ,b1.device  --meter number
       ,b1.consumptionhistid
       ,b1.billdate
       ,b1.numberofdays
       ,b1.fromdate
       ,b1.todate
       ,b1.rate1
       ,nvl(b2.blkuse_1, 0) + 
        nvl(b2.blkuse_2, 0) + 
        nvl(b2.blkuse_3, 0) + 
        nvl(b2.blkuse_4, 0) + 
        nvl(b2.blkuse_5, 0) as tot_use -- creating total use column
       ,nvl(b2.blkamt_1, 0) + 
        nvl(b2.blkamt_2, 0) + 
        nvl(b2.blkamt_3, 0) + 
        nvl(b2.blkamt_4, 0) + 
        nvl(b2.blkamt_5, 0) as tot_amt -- creating total amount column
       ,b2.blkuse_1
       ,b2.blkuse_2
       ,b2.blkuse_3
       ,b2.blkuse_4
       ,b2.blkuse_5
       ,b2.blkamt_1
       ,b2.blkamt_2
       ,b2.blkamt_3
       ,b2.blkamt_4
       ,b2.blkamt_5
       ,b2.blkrate_1
       ,b2.blkrate_2
       ,b2.blkrate_3
       ,b2.blkrate_4
       ,b2.blkrate_5

from blkuse_header b1
     left outer join blkuse b2
     on b1.consumptionhistid = b2.consumptionhistid
     and b1.readsequence = b2.readsequence
     left outer join wacm b3
     on b1.accountnumber = b3.wacm_cust 

),

cteBillableItems as
(
       select hv.cihis_cust,
              hv.cihis_date,
              hv.cihis_service,
              
              hv.cihis_class_num1,
              hv.cihis_rate1,
              case
                when hv.cihis_rate1 in (1,2,10,20,110,201,210)  /* 1=SUFR, 2=, 10=, 20=, 110=, 201=, 210=*/
                  then '0075'
                when hv.cihis_rate1 in (3,11,21,202)
                  then '0100'
                when hv.cihis_rate1 in (22)
                  then '0125'
                when hv.cihis_rate1 in (4,12,23,203)
                  then '0150'
                when hv.cihis_rate1 in (5,13,24,111,204)
                  then '0200'
                when hv.cihis_rate1 in (6,14,25,112,205,210)
                  then '0300'
                when hv.cihis_rate1 in (7,15,26,114,206,220)
                  then '0400'
                when hv.cihis_rate1 in (8,16,27,114,230)
                  then '0600'
                when hv.cihis_rate1 in (17,28,115,240)
                  then '0800'
                when hv.cihis_rate1 in (18,29,116,250)
                  then '1000'
                when hv.cihis_rate1 in (30,260)
                  then '1200'
                /*when hv.cihis_rate1 in ()
                  then '1600'*/
                else '9999'
              end as ssize,--generating the ssize from base item rate
              to_number(to_char(cbi.dateiteminstalled,'YYYYMMDD')) as serviceconnectdate,
              to_number(to_char(cbi.itemremovaldate,'YYYYMMDD'))as serviceclosedate,
              to_date(trim(to_char(hv.cihis_to_date,'00000000')),'mmddyyyy')
                  - to_date(trim(to_char(hv.cihis_from_date,'00000000')),'mmddyyyy') as days,
                  
              (to_number(substr(to_char(hv.cihis_from_date,'00000000'),6,4))*10000)
                  + (to_number(substr(to_char(hv.cihis_from_date,'00000000'),2,2))*100)
                  + (to_number(substr(to_char(hv.cihis_from_date,'00000000'),4,2))*1) as fromdate,
                  
              (to_number(substr(to_char(hv.cihis_to_date,'00000000'),6,4))*10000)
                  + (to_number(substr(to_char(hv.cihis_to_date,'00000000'),2,2))*100)
                  + (to_number(substr(to_char(hv.cihis_to_date,'00000000'),4,2))*1) as todate,
                  
              (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),6,4))*10000)
                  + (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),2,2))*100)
                  + (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),4,2))*1) as efd,
                             --creating the service start date for the month                                                           


              (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),6,4))*10000)
                  + (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),2,2))*100)
                  + (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),4,2))*1) as edt,
                            --creating the service end date for the month                                                          



              sum(hv.cihis_amt) as totalcharges

              
       from CIS.fcihistv hv
       /* cibillableitem gives us the service connect and close dates. */
       left outer join enquesta.cibillableitem cbi on  cbi.customernumber=hv.cihis_cust
                                                   and cbi.servicenumber=hv.cihis_service
       /* It might seem weird joining to the same table,
          but we're just getting the Total Billing Record (95) for the billing period start and end dates. */
       left outer join cis.fcihistv tbr on  tbr.cihis_cust=hv.cihis_cust
                                        and tbr.cihis_date=hv.cihis_date
                                        and tbr.cihis_type_code=95
                                        /* Note: no need to join on service number, it doesn't apply for type_code 95 records. */


       where hv.cihis_class_type1=4      /* 4=Sales. */
             and
             hv.cihis_type_code=34       /* 34=Item Records. */
            



       group by hv.cihis_cust,
                hv.cihis_date,
                hv.cihis_service,
                null,
                hv.cihis_class_num1,
                hv.cihis_rate1,
                case
                  when hv.cihis_rate1 in (1,2,10,20,110,201,210)  /* 1=SUFR, 2=, 10=, 20=, 110=, 201=, 210=*/
                                      then '0075'
                  when hv.cihis_rate1 in (3,11,21,202)
                                      then '0100'
                  when hv.cihis_rate1 in (22)
                                      then '0125'
                  when hv.cihis_rate1 in (4,12,23,203)
                                      then '0150'
                  when hv.cihis_rate1 in (5,13,24,111,204)
                                      then '0200'
                  when hv.cihis_rate1 in (6,14,25,112,205,210)
                                      then '0300'
                  when hv.cihis_rate1 in (7,15,26,114,206,220)
                                      then '0400'
                  when hv.cihis_rate1 in (8,16,27,114,230)
                                      then '0600'
                  when hv.cihis_rate1 in (17,28,115,240)
                                      then '0800'
                  when hv.cihis_rate1 in (18,29,116,250)
                                      then '1000'
                  when hv.cihis_rate1 in (30,260)
                                      then '1200'
                  /*when hv.cihis_rate1 in ()
                    then '1600'*/
                  else '9999'
                end,
                to_number(to_char(cbi.dateiteminstalled,'YYYYMMDD')),
                to_number(to_char(cbi.itemremovaldate,'YYYYMMDD')),
                
                to_date(trim(to_char(hv.cihis_to_date,'00000000')),'mmddyyyy')
                    - to_date(trim(to_char(hv.cihis_from_date,'00000000')),'mmddyyyy'),

                (to_number(substr(to_char(hv.cihis_from_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(hv.cihis_from_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(hv.cihis_from_date,'00000000'),4,2))*1),

                (to_number(substr(to_char(hv.cihis_to_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(hv.cihis_to_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(hv.cihis_to_date,'00000000'),4,2))*1),

                (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),4,2))*1),

                (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),4,2))*1)

       order by hv.cihis_cust,
                hv.cihis_date,
                hv.cihis_service,
                null,
                hv.cihis_class_num1,
                hv.cihis_rate1,
                case
                  when hv.cihis_rate1 in (1,2,10,20,110,201,210)  /* 1=SUFR, 2=, 10=, 20=, 110=, 201=, 210=*/
                                      then '0075'
                  when hv.cihis_rate1 in (3,11,21,202)
                                      then '0100'
                  when hv.cihis_rate1 in (22)
                                      then '0125'
                  when hv.cihis_rate1 in (4,12,23,203)
                                      then '0150'
                  when hv.cihis_rate1 in (5,13,24,111,204)
                                      then '0200'
                  when hv.cihis_rate1 in (6,14,25,112,205,210)
                                      then '0300'
                  when hv.cihis_rate1 in (7,15,26,114,206,220)
                                      then '0400'
                  when hv.cihis_rate1 in (8,16,27,114,230)
                                      then '0600'
                  when hv.cihis_rate1 in (17,28,115,240)
                                      then '0800'
                  when hv.cihis_rate1 in (18,29,116,250)
                                      then '1000'
                  when hv.cihis_rate1 in (30,260)
                                      then '1200'
                  /*when hv.cihis_rate1 in ()
                    then '1600'*/
                  else '9999'
                end,
                to_number(to_char(cbi.dateiteminstalled,'YYYYMMDD')),
                to_number(to_char(cbi.itemremovaldate,'YYYYMMDD')),
                
                to_date(trim(to_char(hv.cihis_to_date,'00000000')),'mmddyyyy')
                    - to_date(trim(to_char(hv.cihis_from_date,'00000000')),'mmddyyyy'),

                (to_number(substr(to_char(hv.cihis_from_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(hv.cihis_from_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(hv.cihis_from_date,'00000000'),4,2))*1),

                (to_number(substr(to_char(hv.cihis_to_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(hv.cihis_to_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(hv.cihis_to_date,'00000000'),4,2))*1),

                (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(tbr.cihis_from_date,'00000000'),4,2))*1),

                (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),6,4))*10000)
                    + (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),2,2))*100)
                    + (to_number(substr(to_char(tbr.cihis_to_date,'00000000'),4,2))*1)
),



cteTotalUsage as  
(
       select ch.accountnumber,
              to_number(to_char(ch.billdate,'YYYYMMDD')) as billdate,
              ch.servicenumbersequence,
              trim(ch.device) as mtr,
              ch.readingclass1,
              ch.rate1,
              case
                when reg.ciregister_cmp_size=1       then '00625'
                when reg.ciregister_cmp_size=2       then '0075'
                when reg.ciregister_cmp_size=3       then '0100'
                when reg.ciregister_cmp_size=13      then '0125'
                when reg.ciregister_cmp_size=4       then '0150'
                when reg.ciregister_cmp_size=5       then '0200'
                when reg.ciregister_cmp_size=6       then '0300'
                when reg.ciregister_cmp_size=7       then '0400'
                when reg.ciregister_cmp_size=8       then '0600'
                when reg.ciregister_cmp_size=9       then '0800'
                when reg.ciregister_cmp_size=10      then '1000'
                when reg.ciregister_cmp_size=11      then '1200'
                when reg.ciregister_cmp_size=12      then '1600'
                else '9999'
              end as ssize,
              null as serviceconnectdate, /* later */
              null as serviceclosedate,  /* later */
              ch.presentreaddate-ch.previousreaddate as days,
              to_number(to_char(ch.previousreaddate,'YYYYMMDD')) as fromdate,
              to_number(to_char(ch.presentreaddate,'YYYYMMDD')) as todate,
              null as billid, /* later */
              wcm.cisnumberofbilledaccount,
              wcm.premisenumber,
              
              sum(ch.consumption) as totalusage,
              sum(ch.billingamount) as totalcharges
              
       from ENQUESTACIS.CICONSUMPTIONHIST ch
       /* wawatercustomer gives us the customer (CIS) number and the premise. */
       left outer join enquesta.wawatercustomermaster wcm on wcm.customernumber=ch.accountnumber
       /* fciregister gives us the size. */
       left outer join cis.fciregister reg on  reg.ciregister_device=ch.device
                                           and reg.ciregister_device_cd=ch.devicecode
                                           and reg.ciregister_num=1 /* For multiregister meters, the size of register 1 dictates the service size.
                                                                       If we ever decide we need both registers, use ch.meterface instead of 1
                                                                       for this element of the join. */

       
       where ch.transactioncode=2  /* 2=Readings. */
             

       group by ch.accountnumber,
                ch.billdate,
                ch.servicenumbersequence,
                trim(ch.device),
                ch.readingclass1,
                ch.rate1,
                case
                  when reg.ciregister_cmp_size=1     then '00625'
                  when reg.ciregister_cmp_size=2     then '0075'
                  when reg.ciregister_cmp_size=3     then '0100'
                  when reg.ciregister_cmp_size=13    then '0125'
                  when reg.ciregister_cmp_size=4     then '0150'
                  when reg.ciregister_cmp_size=5     then '0200'
                  when reg.ciregister_cmp_size=6     then '0300'
                  when reg.ciregister_cmp_size=7     then '0400'
                  when reg.ciregister_cmp_size=8     then '0600'
                  when reg.ciregister_cmp_size=9     then '0800'
                  when reg.ciregister_cmp_size=10    then '1000'
                  when reg.ciregister_cmp_size=11    then '1200'
                  when reg.ciregister_cmp_size=12    then '1600'
                  else '9999'
                end,
                null,
                null,
                ch.presentreaddate-ch.previousreaddate,
                to_number(to_char(ch.previousreaddate,'YYYYMMDD')),
                to_number(to_char(ch.presentreaddate,'YYYYMMDD')),
                null,
                wcm.cisnumberofbilledaccount,
                wcm.premisenumber
                 
       order by ch.accountnumber,
                ch.billdate,
                ch.servicenumbersequence,
                trim(ch.device),
                ch.readingclass1,
                ch.rate1,
                case
                  when reg.ciregister_cmp_size=1       then '00625'
                  when reg.ciregister_cmp_size=2       then '0075'
                  when reg.ciregister_cmp_size=3       then '0100'
                  when reg.ciregister_cmp_size=13      then '0125'
                  when reg.ciregister_cmp_size=4       then '0150'
                  when reg.ciregister_cmp_size=5       then '0200'
                  when reg.ciregister_cmp_size=6       then '0300'
                  when reg.ciregister_cmp_size=7       then '0400'
                  when reg.ciregister_cmp_size=8       then '0600'
                  when reg.ciregister_cmp_size=9       then '0800'
                  when reg.ciregister_cmp_size=10      then '1000'
                  when reg.ciregister_cmp_size=11      then '1200'
                  when reg.ciregister_cmp_size=12      then '1600'
                  else '9999'
                end,
                null,
                null,
                ch.presentreaddate-ch.previousreaddate,
                to_number(to_char(ch.previousreaddate,'YYYYMMDD')),
                to_number(to_char(ch.presentreaddate,'YYYYMMDD')),
                null,
                wcm.cisnumberofbilledaccount,
                wcm.premisenumber
),


cteCombinedData as
(
select
/* This is the Billable Items (flat rate stuff) section. */
       bi.cihis_cust,
       bi.cihis_date,
       bi.cihis_service,
       
       bi.cihis_class_num1,
       bi.cihis_rate1,
       bi.ssize,
       bi.serviceconnectdate,
       bi.serviceclosedate,
       bi.days,
       bi.fromdate,
       bi.todate,
       hf.cihis_reference,  /* Bill Id. */
       wcm.cisnumberofbilledaccount,
       wcm.premisenumber,
       
       bi.totalcharges


from CIS.FCIHISTF hf  /* F=high-level, V=detail. */          

left outer join enquesta.wawatercustomermaster wcm on wcm.customernumber=hf.cihis_cust
left outer join cteBillableItems bi on bi.cihis_cust=hf.cihis_cust and bi.cihis_date=hf.cihis_date



where 
       (hf.cihis_code=99)  /* 99=Billing Record. */
       and
       (bi.cihis_cust is not null)  /* Only where there are Billable Items records. */


union


select
/* Metered Services section. */
       tu.accountnumber,
       tu.billdate,
       tu.servicenumbersequence,
   
       tu.readingclass1,
       tu.rate1,
       tu.ssize,
       tu.serviceconnectdate,
       tu.serviceclosedate,
       tu.days,
       tu.fromdate,
       tu.todate,
       hf.cihis_reference,  /* Bill Id. */
       wcm.cisnumberofbilledaccount,
       wcm.premisenumber,
       tu.totalcharges       


from CIS.FCIHISTF hf  /* F=high-level, V=detail. */          

left outer join enquesta.wawatercustomermaster wcm on wcm.customernumber=hf.cihis_cust
left outer join cteTotalUsage tu on tu.accountnumber=hf.cihis_cust and tu.billdate=hf.cihis_date
/* ...join to customer charge */
/* ...join to tiered usage */



where 
       (hf.cihis_code=99)  /* 99=Billing Record. */
       and
       (tu.accountnumber is not null)

)

,
final_table as(


select cd.cihis_class_num1         as rclass  -- Rate Class.
       --,r11.rsch                    as rate_sch
       ,cd.cihis_rate1              as sch     -- Rate Schedule Type. 
       ,cd.ssize                    as "SIZE"  -- Service size. 
       
       ,cd.cihis_cust               as act     -- Account number.
       ,cd.cisnumberofbilledaccount as cus     -- CIS (customer) number. 
       ,cd.premisenumber            as prm     -- Premise. 
       ,cd.cihis_service            as srvcid  -- Service Id. 
       
       ,cd.cihis_date               as bld     -- Bill Date. 
       ,cd.days                     as dys     -- Number of Days Billed. 
       ,cd.fromdate                 as efd     -- Effective Date. 
       ,cd.todate                   as edt     -- End Date.  
       --,r11.utl_typ                 as utl     -- Utility type
       ,b4.billdate                 as billdate
       ,b4.numberofdays             as numberofdays
       ,b4.tot_use                             --Total Water Use.
       ,b4.tot_amt                             -- Total Water Charges
       ,b4.blkuse_1                 as t1_use  --Tier 1 Water Use.
       ,b4.blkuse_2                 as t2_use  --Tier 2 Water Use.
       ,b4.blkuse_3                 as t3_use  --Tier 3 Water Use.
       ,b4.blkuse_4                 as t4_use  --Tier 4 Water Use.
       ,b4.blkuse_5                 as t5_use  --Tier 5 Water Use.
       ,b4.blkamt_1                 as t1_amt  --Tier 1 Water Charges.
       ,b4.blkamt_2                 as t2_amt  --Tier 2 Water Charges.
       ,b4.blkamt_3                 as t3_amt  --Tier 3 Water Charges.
       ,b4.blkamt_4                 as t4_amt  --Tier 4 Water Charges.
       ,b4.blkamt_5                 as t5_amt  --Tier 5 Water Charges.
       ,b4.blkrate_1                as t1_rate --Tier 1 rate.
       ,b4.blkrate_2                as t2_rate --Tier 2 rate.
       ,b4.blkrate_3                as t3_rate --Tier 3 rate.
       ,b4.blkrate_4                as t4_rate --Tier 4 rate.
       ,b4.blkrate_5                as t5_rate --Tier 5 rate.
   

  from cteCombinedData cd
--   left outer join rate_class r11
--   on cd.cihis_rate1=r11.rate
  left outer join blkuse_final b4
       on cd.premisenumber=b4.premiseid 
       and cd.cihis_date=b4.billdate
  where cd.cihis_date between (select startdte from date_range) and
         (select enddte from date_range) 

)





select t1.*
        --, t2.rsch
from final_table t1
--join rate_class t2 on t1.rclass=t2.rate
--where t2.ratekindid=0



