@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Consumption view for accounting line items'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@Metadata.allowExtensions: true
define view entity ZST7_ACCITM_CHLDPOOL_UMG_CONDF
  as projection on ZST7_ACCITM_CHILD_POOL_UMG_DFT
{
  key item_uuid         as itmuuid,
      bukrs             as compcd,
      belnr             as docno,
      gjahr             as fisyear,
      buzei             as linenum,
      con_uuid          as uuid,
      @ObjectModel.text.element: ['postkeydesc']
      bschl             as postkey,
      @Semantics.text: true
      postkeydesc       as postkeydesc,
      @ObjectModel.text.element: ['acctypdesc']
      koart             as acctyp,
      @Semantics.text: true
      acctyptext        as acctypdesc,
      @ObjectModel.text.element: ['dbcrdesc']
      shkzg             as dbcrindc,
      @Semantics.text: true
      dbcrtext          as dbcrdesc,
      @ObjectModel.text.element: ['bussaredesc']
      gsber             as bussarea,
      @Semantics.text: true
      bussareadesc      as bussaredesc,
      @ObjectModel.text.element: ['taxcddesc']
      mwskz             as taxcode,
      @Semantics.text: true
      taxcddesc         as taxcddesc,
      dmbtr             as amount,
      mwsts             as taxamt,
      waers             as currcode,
      kostl             as costcntr,
      @ObjectModel.text.element: ['venddesc']
      lifnr             as vendor,
      @Semantics.text: true
      venddesc          as venddesc,
      changed_dt_time   as chdttime,
      local_chg_dt_time as locchgdttime,


      //Associations
      _bussAreaDesc,
      _postKeyDesc,
      _taxDesc,
      _vendDesc,
      
      _header : redirected to parent ZST7_ACCHDR_ROOTPL_UMG_CONSDFT

}
