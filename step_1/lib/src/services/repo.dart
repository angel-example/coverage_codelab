import 'package:angel_common/angel_common.dart';
import 'dart:io';
import 'package:angel_file_service/angel_file_service.dart';
import '../models/repo.dart';
export '../models/repo.dart';

AngelConfigurer configureServer() {
  return (Angel app) async {
    app.use('/api/repos',
        new TypedService<Repo>(new JsonFileService(new File('repos_db.json'))));
  };
}
