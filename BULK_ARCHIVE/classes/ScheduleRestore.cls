global class ScheduleRestore implements Schedulable
{
public String Query;
Integer RecordSize; 
global ScheduleRestore (string Query,Integer RecordSize)
{
this.Query=Query;
this.RecordSize=RecordSize;
}
global void execute(SchedulableContext Sc)
{
BatchArchive obj=new BatchArchive(Query);
database.executebatch(obj,RecordSize);
}

}