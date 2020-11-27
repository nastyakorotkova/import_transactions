declare
  vn integer := 0;
begin
  select count(1)
    into vn
    from dual
   where exists (select 1
            from user_objects
           where object_type = 'TABLE'
             and object_name = 'T_TYPE_PROCESS');
  if vn = 0 then
    execute immediate '  
    create table T_TYPE_PROCESS
    (
      idtypeprocess   INTEGER,
      nametypeprocess VARCHAR2(1024)
    )';
  
    execute immediate ' insert into T_TYPE_PROCESS (idtypeprocess, nametypeprocess)
    values (1, ''Заполнение справочника транзакций t_dict'');
    insert into T_TYPE_PROCESS (idtypeprocess, nametypeprocess)
    values (2, ''Запуск Api по каждой транзакции'')';
    commit;
  end if;
end;
/
