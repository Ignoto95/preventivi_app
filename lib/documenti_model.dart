class Documento {
  final int id;
  final int idCliente;
  final String esecutriceImpianto;
  final bool normaTecnicaApplicabile;
  final String testoNormaTecnicaImpiego;
  final bool verificatoCompatibilita;
  final bool progettoArt57;
  final bool tipologiaMaterialiUtilizzati;
  final bool schemaImpianto;
  final bool riferimentoDichiarazioni;
  final bool copiaCertificatoRiconoscimento;
  final bool attestazioneConformita;

  Documento({
    required this.id,
    required this.idCliente,
    required this.esecutriceImpianto,
    required this.normaTecnicaApplicabile,
    required this.testoNormaTecnicaImpiego,
    required this.verificatoCompatibilita,
    required this.progettoArt57,
    required this.tipologiaMaterialiUtilizzati,
    required this.schemaImpianto,
    required this.riferimentoDichiarazioni,
    required this.copiaCertificatoRiconoscimento,
    required this.attestazioneConformita,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id: json['id'],
      idCliente: json['id_cliente'],
      esecutriceImpianto: json['esecutrice_impianto'],
      normaTecnicaApplicabile: json['norma_tecnica_applicabile'] == 1,
      testoNormaTecnicaImpiego: json['testo_norma_tecnica_impiego'],
      verificatoCompatibilita: json['verificato_compatibilita'] == 1,
      progettoArt57: json['progetto_art_5_7'] == 1,
      tipologiaMaterialiUtilizzati: json['tipologia_materiali_utilizzati'] == 1,
      schemaImpianto: json['schema_impianto'] == 1,
      riferimentoDichiarazioni: json['riferimento_dichiarazioni'] == 1,
      copiaCertificatoRiconoscimento: json['copia_certificato_riconoscimento'] == 1,
      attestazioneConformita: json['attestazione_conformita'] == 1,
    );
  }
}
