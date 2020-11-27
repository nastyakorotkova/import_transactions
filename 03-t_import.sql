declare
  vn integer := 0;
begin
  select count(1)
    into vn
    from dual
   where exists (select 1
            from user_objects
           where object_type = 'TABLE'
             and object_name = 'T_IMPORT');
  if vn = 0 then
    execute immediate '
      create table T_IMPORT
      (
        keyid  INTEGER not null,
        dt     DATE not null,
        amount FLOAT not null,
        state  INTEGER default 0
      )';
  end if;
end;
/
