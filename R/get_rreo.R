get_rreo<- function(year, period, report_tp, annex, entity, In_RGPS=FALSE, In_RPPS= FALSE ){


  #test if some variables have just one element

  print(length(report_tp))
  if (length(report_tp)>1){
    stop("Must inform just one report type")
  }

  if (length(annex)>1){
    stop("Must inform just one annex")
  }


  #Test business rules
  if(In_RGPS && In_RPPS){
    stop("Must choose between RGPS and RPPS")
  }

  if(report_tp>2 ){
    stop("Wrong report type")
  }

  df_esf_entidade = tibble(entidade = entity )

  df_esf_entidade<-df_esf_entidade%>%
    mutate(esfera= case_when(
      str_length(entity)== 1 ~"U",
      str_length(entity)== 2 ~"E",
      str_length(entity)== 7 ~"M"
    ) )


  annex_txt<-paste0("RREO-Anexo ",annex, ifelse(In_RGPS," - RGPS", ifelse(In_RPPS," - RPPS","")))

  test<- df_esf_entidade %>%
    anti_join(df_reports%>%
                filter(anexo==annex_txt))

  if (NROW(test)>0){
    stop("One or more entities not suitable for the annex and/or RGPS/RPPS flag informed")
  }


  map_df(year, function(ref_year){

    map_df(period, function(ref_per){

      map_df(entity, function(ref_entity){


        base_address<- "http://apidatalake.tesouro.gov.br/ords/siconfi/tt/rreo"
        annex_conv<-paste0("RREO-Anexo%20",annex)
        if (In_RGPS ){
          annex_conv<-paste0(annex_conv,"%20-%20RGPS")
        }

        if (In_RPPS ){
          annex_conv<-paste0(annex_conv,"%20-%20RPPS")
        }

        exp<- paste0(base_address,
                     "?an_exercicio=", ref_year,
                     "&nr_periodo=", ref_per,
                     "&co_tipo_demonstrativo=", c("RREO", "RREO+Simplificado")[report_tp],
                     "&no_anexo=", annex_conv,
                     "&id_ente=",ref_entity)

        print(exp)

        ls_siconfi<-jsonlite::fromJSON(exp)


        print(ls_siconfi$count)
        if (ls_siconfi$count==0){
          return (tibble())
        }
        df_siconfi<- ls_siconfi[["items"]]

        df_siconfi$valor <- as.numeric(df_siconfi$valor)

        df_siconfi


      })

    })
  })

}