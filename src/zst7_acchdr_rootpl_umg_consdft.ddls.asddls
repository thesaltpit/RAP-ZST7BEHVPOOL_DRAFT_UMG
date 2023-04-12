@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Consumption view for accounting header'
@Metadata.allowExtensions: true
define root view entity ZST7_ACCHDR_ROOTPL_UMG_CONSDFT
  as projection on ZST7_ACCHDR_ROOT_POOL_UMG_DFT
{
  key con_uuid               as uuid,
      @ObjectModel.text.element: ['compcddesc']
      bukrs                  as compcd,
      @Semantics.text: true
      _compCdDesc.descr      as compcddesc,
      belnr                  as docno,
      gjahr                  as fisyear,
// This Consumption tag is added to give F4 help to the document type field
// Here we need to add the basic CDS view and the field name which fetch the data     
      @Consumption.valueHelpDefinition: [{ entity:{ element: 'doctype', name: 'ZST7_DOCTYPE_DESC'}}]
      @ObjectModel.text.element: ['doctypdesc']
      blart                  as doctyp,
      @Semantics.text: true
      _docTypDesc.doctypdesc as doctypdesc,
      bldat                  as docdt,
      @Semantics.systemDateTime.createdAt: true
      cpudt                  as sysdt,
      @Semantics.systemDateTime.createdAt: true
      cputm                  as systime,
      @Semantics.user.createdBy: true
      usnam                  as usernm,
      bktxt                  as doctxt,
      tcode                  as tcode,
      xblnr                  as refno,
      @Semantics.systemDate.createdAt: true
      createddt_time         as crdttime,
      @Semantics.systemDateTime.lastChangedAt: true
      changeddt_time         as chgdttime,
      @Semantics.systemDateTime.lastChangedAt: true
      lastchngdttm           as lastchdttm,

      //Association
      _compCdDesc,
      _docTypDesc,

      _items : redirected to composition child ZST7_ACCITM_CHLDPOOL_UMG_CONDF
}
