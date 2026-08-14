import 'package:flutter/material.dart';
class RecordEventSheet extends StatelessWidget {
  const RecordEventSheet({super.key});
  @override Widget build(context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20,0,20,24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children:[
    Text('What happened?', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height:16),
    Wrap(spacing:12, runSpacing:12, children: const [
      _EventButton(Icons.local_drink_outlined,'Feed'), _EventButton(Icons.bedtime_outlined,'Sleep'),
      _EventButton(Icons.baby_changing_station,'Nappy'), _EventButton(Icons.water_drop_outlined,'Pump'), _EventButton(Icons.note_add_outlined,'Note')])
  ])));
}
class _EventButton extends StatelessWidget { const _EventButton(this.icon,this.label); final IconData icon; final String label;
  @override Widget build(context)=>SizedBox(width:104,height:84,child:FilledButton.tonal(onPressed:(){Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$label entry ready'),action:SnackBarAction(label:'UNDO',onPressed:(){})));},child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon),const SizedBox(height:6),Text(label)])));
}
