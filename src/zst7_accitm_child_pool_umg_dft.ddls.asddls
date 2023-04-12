@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Definition for account items basic view'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZST7_ACCITM_CHILD_POOL_UMG_DFT
  as select from zst7accitm_dftum
//  association        to parent ZST7_ACCHDR_ROOT_POOL_UMG_DFT as _header       on  $projection.bukrs    = _header.bukrs
//                                                                              and $projection.belnr    = _header.belnr
//                                                                              and $projection.gjahr    = _header.gjahr
//                                                                              and $projection.con_uuid = _header.con_uuid
  association        to parent ZST7_ACCHDR_ROOT_POOL_UMG_DFT as _header       on $projection.con_uuid = _header.con_uuid

  // Tax code description
  association [1..1] to zst7taxcddesc_tb                     as _taxDesc      on  $projection.mwskz = _taxDesc.mwskz
  // Vendor description
  association [1..1] to lfa1                                 as _vendDesc     on  $projection.lifnr = _vendDesc.lifnr
  // Business area description
  association [1..1] to tgsbt                                as _bussAreaDesc on  $projection.gsber   = _bussAreaDesc.gsber
                                                                              and _bussAreaDesc.spras = 'E'
  //Posting key description
  association [1..1] to tbslt                                as _postKeyDesc  on  $projection.bschl  = _postKeyDesc.bschl
                                                                              and _postKeyDesc.spras = 'E'

{
  key item_uuid,
      bukrs,
      belnr,
      gjahr,
      buzei,
      con_uuid,
      bschl,
      _postKeyDesc.ltext  as postkeydesc,
      koart,
      shkzg,
      gsber,
      _bussAreaDesc.gtext as bussareadesc,
      mwskz,
      _taxDesc.taxcd_desc as taxcddesc,
      dmbtr,
      mwsts,
      waers,
      kostl,
      lifnr,
      _vendDesc.name1     as venddesc,
      changed_dt_time,
      local_chg_dt_time,

      //Debit/Credit indicator text
      case shkzg
      when 'H' then 'Credit'
      when 'S' then 'Debit'
      end                 as dbcrtext,

      //Account type text
      case koart
      when 'A' then 'Assets'
      when 'D' then 'Customers'
      when 'K' then 'Vendors'
      when 'M' then 'Material'
      when 'S' then 'G/L Account'
      end                 as acctyptext,

      //Associations
      _header,
      _taxDesc,
      _vendDesc,
      _bussAreaDesc,
      _postKeyDesc

}
