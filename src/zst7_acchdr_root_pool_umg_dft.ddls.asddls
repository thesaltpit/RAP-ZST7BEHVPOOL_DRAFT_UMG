@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Definition for account header behaviorial pool'
define root view entity ZST7_ACCHDR_ROOT_POOL_UMG_DFT
  as select from zst7acchdr_dftum
  //When we associate this header CDS with the child definition, here in the header we also need to add composition with the child CDS  
  composition [0..*] of ZST7_ACCITM_CHILD_POOL_UMG_DFT as _items
  //we can also add associations here
  //association [1..1] to zst7_zst7compcd_tb as _compCdDesc on $projection.bukrs = _compCdDesc.bukrs
  association [1..1] to ZST7_COMPCD_DESCR          as _compCdDesc on $projection.bukrs = _compCdDesc.compcd
  association [1..1] to ZST7_DOCTYPE_DESC          as _docTypDesc on $projection.blart = _docTypDesc.doctype
  
{
  key con_uuid,
      bukrs,
      belnr,
      gjahr,
      blart,
      bldat,
      cpudt,
      cputm,
      usnam,
      bktxt,
      tcode,
      xblnr,
      createddt_time,
      changeddt_time,
      lastchngdttm,
      
      //Associations
      _items,
      _compCdDesc,
      _docTypDesc
      
}
