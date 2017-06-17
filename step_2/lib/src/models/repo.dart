library dartcov.models.repo;

import 'package:angel_framework/common.dart';

class Repo extends Model {
  @override
  String id;

  String gitUrl, testScript;

  int linesCovered;

  bool coverageHasBeenCollected;

  @override
  DateTime createdAt, updatedAt;

  Repo(
      {this.id,
      this.gitUrl,
      this.testScript,
      this.linesCovered: -1,
      this.coverageHasBeenCollected: false,
      this.createdAt,
      this.updatedAt});
}
