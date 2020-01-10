{$IFNDEF VCL}
  {$IFNDEF FMX}
    //No built-in way of knowing the difference between applications targeted for FMX or VCL
    //This project is relying on a specific workaround:
    //   Add a project conditional define: $(FrameworkType) which will result in VCL or FMX
    //   This is typically added to the project config: "All Configurations"->"All Platforms"->Conditional Defines

    {$Message Fatal 'VCL or FMX not defined, aborting.  This application contains cross-framework references - add $(FrameworkType) as a conditional define in this project''s configuration.'}

  {$ENDIF}
{$ENDIF}
