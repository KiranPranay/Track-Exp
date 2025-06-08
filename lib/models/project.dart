// lib/models/project.dart

class Project {
  int? id;
  String name;

  Project({this.id, required this.name});

  Map<String, dynamic> toMap() => {if (id != null) 'id': id, 'name': name};

  factory Project.fromMap(Map<String, dynamic> m) =>
      Project(id: m['id'], name: m['name']);
}
