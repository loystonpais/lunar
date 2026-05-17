{
  inputs,
  lib,
  den,
  ...
}: {
  imports = [inputs.den.flakeOutputs.packages];

  den.schema.flake-system.includes.into.host = {system}:
    map (host: {inherit host;})
    (lib.attrValues den.hosts.${system});
}
