class Shop {
  final int? id;
  final String name;
  final String location;

  Shop({this.id, required this.name, required this.location});

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(id: json['id'], name: json['name'], location: json['location']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'location': location};
  }
}
