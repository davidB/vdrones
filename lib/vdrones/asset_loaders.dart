part of vdrones;


class XmlLoader extends AssetLoader {
  Future<dynamic> load(Asset asset, AssetPackTrace tracer) {
    return AssetLoader.httpLoad(asset, 'document', (x) =>  x.responseXml, tracer);
  }

  void delete(dynamic arg) {
  }
}

class SvgImporter extends AssetImporter {

  void initialize(Asset asset) {
    asset.imported = null;
  }

  Future<dynamic> import(dynamic payload, Asset asset, AssetPackTrace tracer) {
    if (payload is Document) {
      asset.imported = payload.documentElement.clone(true) as svg.SvgElement;
      return new Future.value(asset);
    }
    return new Future.value(null);
  }

  void delete(imported) {
  }
}

class AreaJsonImporter extends AssetImporter {
  void initialize(Asset asset) {
    asset.imported = null;
  }

  Future<Asset> import(dynamic payload, Asset asset, AssetPackTrace tracer) {
    tracer.assetImportStart(asset);
    try {
      if (payload is String) {
        try {
          var json = JSON.decode(payload);
          var reader = new AreaReader4Json1();
          asset.imported = reader.area(json);
        } on FormatException catch (e) {
          tracer.assetImportError(asset, e.message);
        }
      } else {
        tracer.assetImportError(asset, "A raw asset was not a String.");
      }
      return new Future.value(asset);
    } catch(e, st) {
      tracer.assetImportError(asset, "failed to import : $e");
    } finally {
      tracer.assetImportEnd(asset);
    }
  }

  void delete(dynamic imported) {
  }
}

class AreaSvgImporter extends AssetImporter {
  void initialize(Asset asset) {
    asset.imported = null;
  }

  Future<Asset> import(dynamic payload, Asset asset, AssetPackTrace tracer) {
    tracer.assetImportStart(asset);
    try {
      if (payload is Document) {
        var reader = new AreaReader4Svg();
        asset.imported = reader.area(payload.documentElement);
      } else {
        tracer.assetImportError(asset, "A raw asset was not a Document.");
      }
      return new Future.value(asset);
    } catch(e, st) {
      tracer.assetImportError(asset, "failed to import : ${e}");
    } finally {
      tracer.assetImportEnd(asset);
    }
  }

  void delete(dynamic imported) {
  }
}
