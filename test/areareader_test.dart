library areareader_test;

import 'package:unittest/unittest.dart';

import 'dart:svg';
import 'package:vector_math/vector_math.dart';
import 'package:vdrones/vdrones.dart';


//import '../lib/vdrones.dart';

main() {
  var sut = new AreaReader4Svg();
  var areaDemo = sut.area(new SvgElement.svg(svgDemo));
  test("read 'gate_in'", () {
    expect(areaDemo.gateIns.length, equals(1));
    expect(areaDemo.gateIns[0].position.storage, equals(new Vector3(162.85714721679688,133.79074096679688,0.0).storage));
    expect(areaDemo.gateIns[0].rx, equals(40.0));
    expect(areaDemo.gateIns[0].ry, equals(40.0));
  });
  test("read 'gate_out'", () {
    expect(areaDemo.gateOuts.length, equals(1));
    expect(areaDemo.gateOuts[0].position.storage, equals(new Vector3(637.142822265625, 372.3621826171875, 0.0).storage));
    expect(areaDemo.gateOuts[0].rx, equals(40.0));
    expect(areaDemo.gateOuts[0].ry, equals(40.0));
  });
}


var svgDemo = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created with Inkscape (http://www.inkscape.org/) -->

<svg xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cc="http://creativecommons.org/ns#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:svg="http://www.w3.org/2000/svg" xmlns="http://www.w3.org/2000/svg" xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" inkscape:version="0.48.4 r9939" version="1.1" id="svg2" height="744.09448" width="1052.3622" sodipodi:docname="map0.svg">
  <defs id="defs4">
    <marker inkscape:stockid="DotM" orient="auto" refY="0" refX="0" id="DotM" style="overflow:visible">
      <path id="path3847" d="m -2.5,-1 c 0,2.76 -2.24,5 -5,5 -2.76,0 -5,-2.24 -5,-5 0,-2.76 2.24,-5 5,-5 2.76,0 5,2.24 5,5 z" style="fill-rule:evenodd;stroke:#000000;stroke-width:1pt" transform="matrix(0.4,0,0,0.4,2.96,0.4)" inkscape:connector-curvature="0" />
    </marker>
    <marker inkscape:stockid="Arrow1Lend" orient="auto" refY="0" refX="0" id="Arrow1Lend" style="overflow:visible">
      <path id="path3786" d="M 0,0 5,-5 -12.5,0 5,5 0,0 z" style="fill-rule:evenodd;stroke:#000000;stroke-width:1pt" transform="matrix(-0.8,0,0,-0.8,-10,0)" inkscape:connector-curvature="0" />
    </marker>
    <marker style="overflow:visible" id="DistanceEnd" refX="0" refY="0" orient="auto" inkscape:stockid="DistanceEnd">
      <g id="g2301">
        <path style="fill:none;stroke:#ffffff;stroke-width:1.14999998;stroke-linecap:square" d="M 0,0 -2,0" id="path2316" inkscape:connector-curvature="0" />
        <path style="fill:#000000;fill-rule:evenodd;stroke:none" d="M 0,0 -13,4 -9,0 -13,-4 0,0 z" id="path2312" inkscape:connector-curvature="0" />
        <path style="fill:none;stroke:#000000;stroke-width:1;stroke-linecap:square" d="M 0,-4 0,40" id="path2314" inkscape:connector-curvature="0" />
      </g>
    </marker>
  </defs>
  <sodipodi:namedview id="base" pagecolor="#ffffff" bordercolor="#666666" borderopacity="1.0" inkscape:pageopacity="0.0" inkscape:pageshadow="2" inkscape:zoom="0.7" inkscape:cx="402.97858" inkscape:cy="258.10095" inkscape:document-units="px" inkscape:current-layer="layer1" showgrid="true" inkscape:snap-global="true" showguides="true" inkscape:guide-bbox="true" borderlayer="false" inkscape:window-width="1680" inkscape:window-height="1037" inkscape:window-x="0" inkscape:window-y="0" inkscape:window-maximized="1">
    <inkscape:grid type="xygrid" id="grid3002" empspacing="5" visible="true" enabled="true" snapvisiblegridlinesonly="true" dotted="false" empcolor="#00007c" empopacity="0.25098039" />
  </sodipodi:namedview>
  <metadata id="metadata7">
    <rdf:RDF>
      <cc:Work rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <g inkscape:label="Calque 1" inkscape:groupmode="layer" id="layer1" transform="translate(0,-305.71429)">
    <g id="g5149" class="gate_in">
      <path sodipodi:end="6.2761735" sodipodi:start="0" transform="translate(-17.142857,275.41056)" d="m 220,164.09448 a 40,40 0 1 1 -9.8e-4,-0.28047 L 180,164.09448 z" sodipodi:ry="40" sodipodi:rx="40" sodipodi:cy="164.09448" sodipodi:cx="180" id="path5102" style="fill:#00ffff;fill-opacity:1;fill-rule:nonzero;stroke:none" sodipodi:type="arc" />
    </g>
    <g id="g3007" transform="translate(488.57143,177.14285)" class="mobile_wall">
      <path inkscape:connector-curvature="0" id="path2989" d="M 249.84463,236.03531 207.14286,412.36219" style="fill:none;stroke:#000000;stroke-width:0.72899997;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;marker-start:url(#DotM);marker-mid:url(#DotM);marker-end:url(#Arrow1Lend)" sodipodi:nodetypes="cc" />
      <rect y="179.50505" x="248.57143" height="57.20948" width="267.69058" id="rect2985" style="fill:#db3b4c;fill-opacity:1;fill-rule:nonzero;stroke:none" />
    </g>
    <g id="g4987" style="fill:#666666;fill-opacity:1" transform="translate(30,54.285714)" class="static_wall">
      <rect y="852.36218" x="561.42859" height="39.999992" width="380" id="rect5082-8" style="fill:#666666;fill-opacity:1;fill-rule:nonzero;stroke:none" />
      <rect y="619.50507" x="71.428574" height="39.999992" width="380" id="rect5082" style="fill:#666666;fill-opacity:1;fill-rule:nonzero;stroke:none" />
      <rect style="fill:#666666;fill-opacity:1;fill-rule:nonzero;stroke:none" id="rect5074" width="40" height="740" x="0" y="4.0944786" transform="translate(-30,253.98199)" />
      <rect y="258.07648" x="990" height="740" width="40" id="rect5076" style="fill:#666666;fill-opacity:1;fill-rule:nonzero;stroke:none" />
      <rect style="fill:#666666;fill-opacity:1;fill-rule:nonzero;stroke:none" id="rect5078" width="980" height="39.999992" x="10" y="958.07648" />
      <rect y="258.07648" x="8.5714283" height="39.999992" width="981.42859" id="rect5080" style="fill:#666666;fill-opacity:1;fill-rule:nonzero;stroke:none" />
    </g>
    <g id="g5152" class="gate_out">
      <path sodipodi:type="arc" style="fill:#ff6600;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path5116" sodipodi:cx="180" sodipodi:cy="164.09448" sodipodi:rx="40" sodipodi:ry="40" d="m 220,164.09448 a 40,40 0 1 1 -9.8e-4,-0.28047 L 180,164.09448 z" transform="translate(457.14286,513.98199)" sodipodi:start="0" sodipodi:end="6.2761735" />
    </g>
    <g id="g5143" class="cube_generator">
      <rect transform="translate(0,305.71429)" y="64.094482" x="240" height="280" width="220" id="rect5141" style="fill:#611e8b;fill-opacity:1;fill-rule:nonzero;stroke:none" />
      <rect style="fill:#611e8b;fill-opacity:1;fill-rule:nonzero;stroke:none" id="rect5155" width="360" height="120" x="120" y="424.09448" transform="translate(0,305.71429)" />
    </g>
    <path sodipodi:type="star" style="fill:#ff0000;fill-opacity:1;fill-rule:nonzero;stroke:none" id="path5158" sodipodi:sides="5" sodipodi:cx="0" sodipodi:cy="744.09448" sodipodi:r1="20" sodipodi:r2="10" sodipodi:arg1="0" sodipodi:arg2="0.62831853" inkscape:flatsided="false" inkscape:rounded="0" inkscape:randomized="0" d="m 20,744.09448 -11.9098301,5.87785 -1.90983,13.14328 -9.2705098,-9.51056 -13.0901701,2.24514 6.18034,-11.75571 -6.18034,-11.7557 13.09017,2.24514 9.2705099,-9.51057 1.90983,13.14328 z" transform="translate(0,305.71429)" inkscape:transform-center-x="-1.9098301" class="origin" />
  </g>
  <g inkscape:groupmode="layer" id="layer2" inkscape:label="tool" transform="translate(0,-308.2677)" class="ignore">
    <g id="g5146" class="vdrone">
      <path inkscape:connector-curvature="0" id="path5119" d="m -80,424.09448 c -20,60 -20,60 -20,60 l 40,0 0,0 z" style="fill:#611e8b;fill-opacity:1;stroke:#000000;stroke-width:1;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-opacity:1;stroke-dasharray:none;stroke-dashoffset:0" />
    </g>
  </g>
</svg>
''';