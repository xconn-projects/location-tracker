import "dart:convert";

GetMyModel getMyModelFromJson(String str) => GetMyModel.fromJson(json.decode(str));

String getMyModelToJson(GetMyModel data) => json.encode(data.toJson());

class GetMyModel {
  GetMyModel({
    double? latitude,
    double? longitude,
  }) {
    _latitude = latitude;
    _longitude = longitude;
  }

  GetMyModel.fromJson(Map json) {
    _latitude = json["latitude"];
    _longitude = json["longitude"];
  }

  double? _latitude;
  double? _longitude;

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map["latitude"] = _latitude;
    map["longitude"] = _longitude;
    return map;
  }
}
