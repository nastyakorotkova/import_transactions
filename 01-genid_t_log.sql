declare
 vn integer := 0;
begin
  select count(1) into vn from dual where exists (select 1 from user_objects where object_type = 'SEQUENCE' and object_name = 'GENID_T_LOG');
  if vn = 0 then
    execute immediate('create sequence GENID_T_LOG
      minvalue 1
      maxvalue 999999999999999999999999
      start with 1
      increment by 1
      cache 20');
  end if;
end;
/
