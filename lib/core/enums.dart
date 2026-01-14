enum TimeRange { daily, weekly, monthly }

enum UploadStage {
  uploadingPhotos,
  uploadingPDF,
  submitting,
  compressingImages,
}

enum Environment {
  dev('dev'),
  prod('prod');

  final String value;
  const Environment(this.value);
}
