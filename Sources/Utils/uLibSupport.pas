unit uLibSupport;

interface

uses
  { Common }
  uFileExplorer,
  { TM }
  uUtils;

procedure LoadLibraries;

implementation

procedure _LoadLibrary(const Path: String);
begin

end;

procedure LoadLibraries;
var
  RootPath: String;
begin

  RootPath := ExeDir;

  ExploreFiles(RootPath, '*.dll',

      procedure (const _FileName: String)
      begin

        _LoadLibrary(RootPath + '\' + _FileName);

      end

  );

end;

end.
