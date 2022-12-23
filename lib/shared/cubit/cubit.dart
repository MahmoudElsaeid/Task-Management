
import 'package:app_first/modules/todo_app/archived_tasks/archived_Tasks_screen.dart';
import 'package:app_first/modules/todo_app/done_tasks/done_tasks_screen.dart';
import 'package:app_first/modules/todo_app/new_tasks/new_tasks_screen.dart';
import 'package:app_first/shared/cubit/states.dart';
import 'package:app_first/shared/network/local/cache_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

class AppCubit extends Cubit<AppStates>
{
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);

  int currenIndex = 0;

  List<Widget> screens =
  [
    NewTasksScreen(),
    DoneTasksScreen(),
    ArchivedTasksScreen(),
  ];

  List<String> titels =
  [
    'New Tasks',
    'Done Tasks',
    'Archived Tasks',
  ];
  void changeIndex(int index)
  {
    currenIndex = index;
    emit(AppChangeBottomNavBarState());
  }

  Database? database;
  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];

  void createDatabase()
  {
    openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version)
      {
        print('database Created');
        database.execute('Create Table tasks(id INTEGER PRIMARY KEY, title TEXT, date TEXT, time TEXT, status TEXT)').then((value)
        {
          print('Table Created');
        }).catchError((error)
        {
          print('Error when creating table ${error.toString}');
        });
      },
      onOpen: (database)
      {
        getDataFromDatabase(database);
        print('database opened');
      },
    ).then((value)
    {
      database = value;
      emit(AppCreateDatabaseState());
    });
  }

  Future insertToDatabase({
    required String title,
    required String time,
    required String date,
  })
  async{
    await database?.transaction((txn)
    async {
      txn.rawInsert(
          'INSERT INTO TASKS (title, date, time, status) VALUES("$title", "$date", "$time", "new")'
      ).then((value)
      {
        print('$value inserted successfully');
        emit(AppInsertDatabaseState());

        getDataFromDatabase(database);
      }).catchError((error) {
        print('Error when inserting New record ${error.toString()}');
      });
      return null;
    });
  }

  void getDataFromDatabase(database)
  {
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];
    emit(AppGetDatabaseLoadingState());

    database.rawQuery('SELECT * FROM tasks').then((value)
    {

      value.forEach((element)
      {
        if(element['status'] == 'new')
          newTasks.add(element);
        else if(element['status'] == 'done')
        doneTasks.add(element);
        else archivedTasks.add(element);

      }
      );
      emit(AppGetDatabaseState());
    });
  }

  void updateData({
    required String status,
    required int id,
})
  async{
    database?.rawUpdate(
        'UPDATE tasks SET status = ? WHERE id = ?',
        ['$status', id],
    ).then((value)
    {
      getDataFromDatabase(database);
      emit(AppUpdateDatabaseState());
    });
  }

  void deleteData({
    required int id,
  })
  async{
    database?.rawDelete(
        'DELETE FROM tasks WHERE id = ?', [id]
    ).then((value)
    {
      getDataFromDatabase(database);
      emit(AppDeleteDatabaseState());
    });
  }

  bool isBottomSheetShown = false;
  IconData fabIcon =Icons.edit;

  void changeBottomSheetState({
    required bool isShow,
    required IconData Icon,})
  {
    isBottomSheetShown = isShow;
    fabIcon = Icon;
    emit(AppChangeBottomSheetState());
  }

  bool isDark = false;
  void changeAppMode({bool? formShared})
  {
    if (formShared != null) {
      isDark = formShared;
      emit(AppChangeModeState());
    }else
      {
      isDark = !isDark;
      CacheHelper.putBoolean(key: 'isDark', value: isDark).then((value)
      {
        emit(AppChangeModeState());
      });
      }
  }

}