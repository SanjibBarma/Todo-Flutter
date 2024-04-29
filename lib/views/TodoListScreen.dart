import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

import '../helper/DBHelper.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<String> tasks = [];
  Map<String, bool> taskCompletedMap = {}; // Map to store completion status
  List<String> filteredTasks = [];
  List<String> loadedTasks = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Todo List'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('Close'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                print('Search query changed: $value');
                setState(() {
                  filteredTasks = tasks
                      .where((task) => task.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                  print('Filtered tasks: $filteredTasks');
                });
              },
            ),
          ),
          Expanded(
            child: filteredTasks.isEmpty
                ? const Center(
              child: Text(
                'No task added',
                style: TextStyle(fontSize: 20.0),
              ),
            )
                : ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final isCompleted = taskCompletedMap[task] ?? false; // Retrieve completion status
                return Dismissible(
                  key: Key(task),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    if (isCompleted) {
                      // If task is completed, prevent dismissal
                      return false;
                    } else {
                      // Otherwise, show confirmation dialog
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Task'),
                            content:
                            Text('Are you sure you want to delete the task "$task"?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  onDismissed: (direction) {
                    _removeTask(task);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isCompleted,
                        onChanged: (isChecked) async {
                          bool? isCheckedFromDB = await DBHelper.getTaskCheckedStatus(task);
                          Map<String, dynamic>? taskRow = await DBHelper.getTaskRow(task);
                          if (isCheckedFromDB != null) {
                            setState(() {
                              taskCompletedMap[task] = isCheckedFromDB; // Update completion status
                              if (isCheckedFromDB) {
                                // print("srarys ${isCheckedFromDB}");
                                print("Task \"$task\" is selected and retrieved from the database.");
                                if (taskRow != null) {
                                  print("Full column: $taskRow");
                                }
                                DBHelper.updateTask(task, false);
                              }else{
                                DBHelper.updateTask(task, true);
                                // print("srarys ${isCheckedFromDB}");
                                print("Task \"$task\" is selected and retrieved from the database.");
                                if (taskRow != null) {
                                  print("Full column: $taskRow");
                                }
                              }
                            });
                          }
                        },
                      ),
                      title: Text(
                        task,
                        style: isCompleted
                            ? const TextStyle(decoration: TextDecoration.lineThrough)
                            : null,
                      ),
                      trailing: isCompleted
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Task'),
                                content: Text(
                                    'Are you sure you want to delete the task "$task"?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _removeTask(task);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTask(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTask(BuildContext context) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Task'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String task = controller.text.trim();
                if (task.isNotEmpty) {
                  if (!tasks.contains(task)) {
                    print('Adding task: $task');
                    await DBHelper.insertTask(task, false);
                    setState(() {
                      tasks.insert(0, task); // Prepend the new task to the tasks list
                      taskCompletedMap[task] = false; // Initialize completion status
                      filteredTasks.insert(0, task); // Prepend the new task to the filteredTasks list
                    });
                    print('Task added successfully');
                  } else {
                    print('Task already exists: $task');
                    Fluttertoast.showToast(
                      msg: "Task already exists",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                    );
                  }
                  Navigator.of(context).pop();
                } else {
                  print('Task is empty');
                  Fluttertoast.showToast(
                    msg: "Please write a task",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _loadTasks() async {
    loadedTasks = await DBHelper.getTasks();
    setState(() {
      tasks = loadedTasks;
      // Initialize completion status for each task
      taskCompletedMap = Map.fromIterable(tasks, key: (task) => task, value: (_) => false);
      filteredTasks = loadedTasks; // Initially set to all tasks
    });
  }

  void _removeTask(String task) async {
    setState(() {
      print('Removing task: $task');
      tasks.remove(task);
      taskCompletedMap.remove(task); // Remove completion status
      filteredTasks.remove(task);
    });

    // Delete task from the database
    await DBHelper.deleteTask(task);

    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(
        content: Text('Task \"$task\" deleted'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              tasks.insert(0, task);
              taskCompletedMap[task] = false; // Mark as not completed
              filteredTasks.insert(0, task);
            });
            // You might need to add the task back to the database if you want undo functionality.
          },
        ),
      ),
    );
  }
}

// class TodoListScreen extends StatefulWidget {
//   const TodoListScreen({super.key});
//
//   @override
//   _TodoListScreenState createState() => _TodoListScreenState();
// }
//
// class _TodoListScreenState extends State<TodoListScreen> {
//   List<String> tasks = [];
//   Map<String, bool> taskCompletedMap = {}; // Map to store completion status
//   List<String> filteredTasks = [];
//   List<String> loadedTasks = [];
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadTasks();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey,
//       appBar: AppBar(
//         title: const Text('Todo List'),
//         leading: IconButton(
//           icon: const Icon(Icons.menu),
//           onPressed: () {
//             _scaffoldKey.currentState!.openDrawer();
//           },
//         ),
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             const DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//               ),
//               child: Text(
//                 'Menu',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ListTile(
//               title: Text('Close'),
//               onTap: () {
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               decoration: const InputDecoration(
//                 labelText: 'Search',
//                 prefixIcon: Icon(Icons.search),
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 print('Search query changed: $value');
//                 setState(() {
//                   filteredTasks = tasks
//                       .where((task) => task.toLowerCase().contains(value.toLowerCase()))
//                       .toList();
//                   print('Filtered tasks: $filteredTasks');
//                 });
//               },
//             ),
//           ),
//           Expanded(
//             child: filteredTasks.isEmpty
//                 ? const Center(
//               child: Text(
//                 'No task added',
//                 style: TextStyle(fontSize: 20.0),
//               ),
//             )
//                 : ListView.builder(
//               itemCount: filteredTasks.length,
//               itemBuilder: (context, index) {
//                 final task = filteredTasks[index];
//                 final isCompleted = taskCompletedMap[task] ?? false; // Retrieve completion status
//                 return Dismissible(
//                   key: Key(task),
//                   direction: DismissDirection.endToStart,
//                   background: Container(
//                     color: Colors.red,
//                     alignment: Alignment.centerRight,
//                     padding: EdgeInsets.symmetric(horizontal: 20.0),
//                     child: const Icon(
//                       Icons.delete,
//                       color: Colors.white,
//                     ),
//                   ),
//                   confirmDismiss: (direction) async {
//                     if (isCompleted) {
//                       // If task is completed, prevent dismissal
//                       return false;
//                     } else {
//                       // Otherwise, show confirmation dialog
//                       return await showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return AlertDialog(
//                             title: const Text('Delete Task'),
//                             content:
//                             Text('Are you sure you want to delete the task "$task"?'),
//                             actions: <Widget>[
//                               TextButton(
//                                 onPressed: () => Navigator.of(context).pop(false),
//                                 child: const Text('Cancel'),
//                               ),
//                               TextButton(
//                                 onPressed: () => Navigator.of(context).pop(true),
//                                 child: const Text('Delete'),
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                     }
//                   },
//                   onDismissed: (direction) {
//                     _removeTask(task);
//                   },
//                   child: Container(
//                     margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     child: ListTile(
//                       leading: Checkbox(
//                         value: isCompleted,
//                         onChanged: (isChecked) {
//                           setState(() {
//                             taskCompletedMap[task] = isChecked!; // Update completion status
//                           });
//                         },
//                       ),
//                       title: Text(
//                         task,
//                         style: isCompleted
//                             ? const TextStyle(decoration: TextDecoration.lineThrough)
//                             : null,
//                       ),
//                       trailing: isCompleted
//                           ? null
//                           : IconButton(
//                         icon: const Icon(Icons.delete),
//                         onPressed: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 title: const Text('Delete Task'),
//                                 content: Text(
//                                     'Are you sure you want to delete the task "$task"?'),
//                                 actions: <Widget>[
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                     },
//                                     child: const Text('Cancel'),
//                                   ),
//                                   TextButton(
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                       _removeTask(task);
//                                     },
//                                     child: const Text('Delete'),
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _addTask(context);
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
//
//   void _addTask(BuildContext context) {
//     TextEditingController controller = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Add Task'),
//           content: TextField(
//             controller: controller,
//             autofocus: true,
//             decoration: InputDecoration(labelText: 'Task'),
//           ),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 String task = controller.text.trim();
//                 if (task.isNotEmpty) {
//                   if (!tasks.contains(task)) {
//                     print('Adding task: $task');
//                     await DBHelper.insertTask(task);
//                     setState(() {
//                       tasks.insert(0, task); // Prepend the new task to the tasks list
//                       taskCompletedMap[task] = false; // Initialize completion status
//                       filteredTasks.insert(0, task); // Prepend the new task to the filteredTasks list
//                     });
//                     print('Task added successfully');
//                   } else {
//                     print('Task already exists: $task');
//                     Fluttertoast.showToast(
//                       msg: "Task already exists",
//                       toastLength: Toast.LENGTH_SHORT,
//                       gravity: ToastGravity.BOTTOM,
//                       backgroundColor: Colors.red,
//                       textColor: Colors.white,
//                     );
//                   }
//                   Navigator.of(context).pop();
//                 } else {
//                   print('Task is empty');
//                   Fluttertoast.showToast(
//                     msg: "Please write a task",
//                     toastLength: Toast.LENGTH_SHORT,
//                     gravity: ToastGravity.BOTTOM,
//                     backgroundColor: Colors.red,
//                     textColor: Colors.white,
//                   );
//                 }
//               },
//               child: Text('Add'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _loadTasks() async {
//     loadedTasks = await DBHelper.getTasks();
//     setState(() {
//       tasks = loadedTasks;
//       // Initialize completion status for each task
//       taskCompletedMap = Map.fromIterable(tasks, key: (task) => task, value: (_) => false);
//       filteredTasks = loadedTasks; // Initially set to all tasks
//     });
//   }
//
//   void _removeTask(String task) async {
//     setState(() {
//       print('Removing task: $task');
//       tasks.remove(task);
//       taskCompletedMap.remove(task); // Remove completion status
//       filteredTasks.remove(task);
//     });
//
//     // Delete task from the database
//     await DBHelper.deleteTask(task);
//
//     ScaffoldMessenger.of(context as BuildContext).showSnackBar(
//       SnackBar(
//         content: Text('Task \"$task\" deleted'),
//         duration: Duration(seconds: 2),
//         action: SnackBarAction(
//           label: 'Undo',
//           onPressed: () {
//             setState(() {
//               tasks.insert(0, task);
//               taskCompletedMap[task] = false; // Mark as not completed
//               filteredTasks.insert(0, task);
//             });
//             // You might need to add the task back to the database if you want undo functionality.
//           },
//         ),
//       ),
//     );
//   }
// }
