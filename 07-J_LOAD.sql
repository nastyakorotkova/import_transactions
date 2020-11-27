declare
  vn integer := 0;
begin
  select count(1)
    into vn
    from dual
   where exists (select 1
            from all_objects
           where object_name = 'J_LOAD');
           
  if vn = 0 then           
    sys.dbms_scheduler.create_job(job_name            => 'J_LOAD',
                                  job_type            => 'PLSQL_BLOCK',
                                  job_action          => 'declare 
    i_job_no BINARY_INTEGER;
    begin 
      if pkg_load_t.askProcess(1) = 1 then
        for i in 1..pkg_load_t.c_load_processes loop      
          dbms_job.submit(JOB => i_job_no, what =>  ''pkg_load_t.runLoad(''|| i || '');'');
        end loop;
        commit;
      end if;
    end;',
                                  start_date          => to_date('27-11-2020 00:00:00', 'dd-mm-yyyy hh24:mi:ss'),
                                  repeat_interval     => 'Freq=Minutely;Interval=1',
                                  end_date            => to_date(null),
                                  job_class           => 'DEFAULT_JOB_CLASS',
                                  enabled             => true,
                                  auto_drop           => false,
                                  comments            => '');
  end if;
end;
/
