#!/usr/bin/env cwl-runner

class: ExpressionTool
id: MaxContamination
label: MaxContamination
cwlVersion: v1.1

requirements:
  InlineJavascriptRequirement: {}

# In the original WDL implementation, contamination_major and contamination_minor are optional.
# However, we changed them to mandatory parameters since undefined values may cause incorrect calculation.
# (Actually the values are always given from the upstream part of the workflow and there is no possibility
# that these inputs are undefined.)
inputs:
  run_contamination:
    type: boolean
  hasContamination:
    type: string?
  contamination_major:
    type: float
  contamination_minor:
    type: float
  verifyBamID:
    type: float?

outputs:
  max_contamination:
    type: float

expression: |
  ${
    var hc_contamination;
    if (inputs.run_contamination && inputs.hasContamination == "YES") {
      hc_contamination = inputs.contamination_major == 0.0 ? inputs.contamination_minor : 1.0 - inputs.contamination_major;
    } else {
      hc_contamination = 0.0
    };
    var max_contamination = (inputs.verifyBamID != null && inputs.verifyBamID > hc_contamination) ? inputs.verifyBamID : hc_contamination;
    return {"max_contamination":  max_contamination};
  }
