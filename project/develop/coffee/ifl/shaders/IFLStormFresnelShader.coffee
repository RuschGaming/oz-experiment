class IFLStormFresnelShader

    uniforms : null
        
    constructor:->
        @uniforms = THREE.UniformsUtils.merge [
            THREE.UniformsLib[ "common" ]
            #THREE.UniformsLib[ "bump" ]
            #THREE.UniformsLib[ "normalmap" ]
            #THREE.UniformsLib[ "fog" ]
            #THREE.UniformsLib[ "lights" ]
            #THREE.UniformsLib[ "shadowmap" ]
            THREE.UniformsLib[ "envmap" ]
            {
                #"ambient"  : { type: "c", value: new THREE.Color( 0xffffff ) }
                #"emissive" : { type: "c", value: new THREE.Color( 0x000000 ) }
                #"specular" : { type: "c", value: new THREE.Color( 0x111111 ) }
                #"shininess": { type: "f", value: 30 }
                #"diffuseMultiplier": { type: "f", value: 1 }
                "envmapMul": { type: "f", value: 3.0 }
                "envmapMix": { type: "f", value: 0.60 }
                "envmapPow": { type: "f", value: 1.0 }
                "specmapMul": { type: "f", value: 0.6 }
                "specmapPow": { type: "f", value: 0.1 }
                "fresnelPower": { type: "f", value: 0.0 }
                "specMap": { type: "t", value: null },
                "cubeX": { type: "f", value: -126.0 }
                "cubeY": { type: "f", value: 107.0 }
                "cubeZ": { type: "f", value: 51.0 }
            }
        ]

    vertexShader: [

        "#define PHONG"
        "#define USE_ENVMAP"


        THREE.ShaderChunk[ "map_pars_vertex" ]
        THREE.ShaderChunk[ "lightmap_pars_vertex" ]
        #THREE.ShaderChunk[ "envmap_pars_vertex" ]
        #THREE.ShaderChunk[ "lights_phong_pars_vertex" ]
        THREE.ShaderChunk[ "color_pars_vertex" ]
        THREE.ShaderChunk[ "morphtarget_pars_vertex" ]
        THREE.ShaderChunk[ "skinning_pars_vertex" ]
        #THREE.ShaderChunk[ "shadowmap_pars_vertex" ]


        "varying vec3 vViewPosition;"
        "varying vec3 vNormal;"
        "varying vec3 vObjectNormal;"
        "varying vec3 vReflect;"
        "varying vec3 vWorldPosition;"

        "void main() {",

            THREE.ShaderChunk[ "map_vertex" ]
            THREE.ShaderChunk[ "lightmap_vertex" ]
            THREE.ShaderChunk[ "color_vertex" ]

            THREE.ShaderChunk[ "morphnormal_vertex" ]
            THREE.ShaderChunk[ "skinbase_vertex" ]
            THREE.ShaderChunk[ "skinnormal_vertex" ]
            THREE.ShaderChunk[ "defaultnormal_vertex" ]

            "vNormal = transformedNormal;",
            "vObjectNormal = objectNormal;",

            THREE.ShaderChunk[ "morphtarget_vertex" ]
            THREE.ShaderChunk[ "skinning_vertex" ]
            THREE.ShaderChunk[ "default_vertex" ]
            
            "vViewPosition = -mvPosition.xyz;"

            THREE.ShaderChunk[ "worldpos_vertex" ]

            #THREE.ShaderChunk[ "envmap_vertex" ]
            "#if defined( USE_ENVMAP ) && ! defined( USE_BUMPMAP ) && ! defined( USE_NORMALMAP )",
                "vec3 nWorld = mat3( modelMatrix[ 0 ].xyz, modelMatrix[ 1 ].xyz, modelMatrix[ 2 ].xyz ) * objectNormal;",
                "vReflect = reflect( normalize( mPosition.xyz - cameraPosition ), normalize( nWorld.xyz ) );",
            "#endif"

            #THREE.ShaderChunk[ "lights_phong_vertex" ]
            "vWorldPosition = mPosition.xyz;"


            #THREE.ShaderChunk[ "shadowmap_vertex" ]


        "}"

    ].join("\n")

    fragmentShader: [


        THREE.ShaderChunk[ "color_pars_fragment" ]
        THREE.ShaderChunk[ "map_pars_fragment" ]
        THREE.ShaderChunk[ "lightmap_pars_fragment" ]
        #THREE.ShaderChunk[ "envmap_pars_fragment" ]
        THREE.ShaderChunk[ "fog_pars_fragment" ]
        #THREE.ShaderChunk[ "lights_phong_pars_fragment" ]
        THREE.ShaderChunk[ "shadowmap_pars_fragment" ]
        #THREE.ShaderChunk[ "bumpmap_pars_fragment" ]
        # THREE.ShaderChunk[ "normalmap_pars_fragment" ]
        THREE.ShaderChunk[ "specularmap_pars_fragment" ]

        "uniform vec3 diffuse;",
        "uniform float opacity;",

        #"uniform vec3 ambient;",
        #"uniform vec3 emissive;",
        #"uniform vec3 specular;",
        #"uniform float shininess;",
        #"uniform float diffuseMultiplier;",
        "uniform float envmapMix;",
        "uniform float envmapMul;",
        "uniform float envmapPow;",
        "uniform float specmapMul;",
        "uniform float specmapPow;",
        "uniform float fresnelPower;",
        "uniform float cubeX;",
        "uniform float cubeY;",
        "uniform float cubeZ;",
        "uniform samplerCube specMap;",

        "varying vec3 vWorldPosition;"
        "varying vec3 vViewPosition;"
        "varying vec3 vNormal;"
        "varying vec3 vObjectNormal;"

        "#ifdef USE_ENVMAP",
            "varying vec3 vReflect;",
            "uniform float reflectivity;"
            "uniform samplerCube envMap;"
            "uniform float flipEnvMap;"
            "uniform int combine;"
        "#endif"        

        "#ifdef USE_NORMALMAP"

            "uniform sampler2D normalMap;"
            "uniform vec2 normalScale;"

            # Per-Pixel Tangent Space Normal Mapping
            # http://hacksoflife.blogspot.ch/2009/11/per-pixel-tangent-space-normal-mapping.html

            "vec3 perturbNormal2Arb( vec3 eye_pos, vec3 surf_norm ) {"

                "vec3 q0 = dFdx( eye_pos.xyz );"
                "vec3 q1 = dFdy( eye_pos.xyz );"
                "vec2 st0 = dFdx( vUv.st );"
                "vec2 st1 = dFdy( vUv.st );"

                "vec3 S = normalize(  q0 * st1.t - q1 * st0.t );"
                "vec3 T = normalize( -q0 * st1.s + q1 * st0.s );"
                "vec3 N = normalize( surf_norm );"

                "vec3 nmap = texture2D( normalMap, vUv ).xyz;"
                "nmap.y = 1.0 - nmap.y;"
                # "nmap.x = 1.0 - nmap.x;"
                # "nmap.z = 1.0 - nmap.z;"
                "vec3 mapN = nmap * 2.0 - 1.0;"
                "mapN.xy = normalScale * mapN.xy;"
                "mat3 tsn = mat3( S, T, N );"
                "return normalize( tsn * mapN );"

            "}"

        "#endif"    





        "void main() {",

            "gl_FragColor = vec4( diffuse, opacity );"

            # THREE.ShaderChunk[ "map_fragment" ]
            "#ifdef USE_MAP",

                # "#ifdef GAMMA_INPUT",

                #     "vec4 texelColor = texture2D( map, vUv );",
                #     "texelColor.xyz *= texelColor.xyz;",

                #     "gl_FragColor = gl_FragColor * texelColor;",

                # "#else",

                    "gl_FragColor = texture2D( map, vUv );"

                # "#endif",

            "#endif"            
            "#ifdef USE_LIGHTMAP",
                "vec4 map2col = texture2D( lightMap, vUv2 );"
                # "if(map2col.w < 0.5){"
                #     "discard;"
                # "}"
                "gl_FragColor *= map2col;"#mix(gl_FragColor, map2col,0.5);",
                "gl_FragColor.w = map2col.w;"

            "#endif"
            THREE.ShaderChunk[ "alphatest_fragment" ]
            #THREE.ShaderChunk[ "specularmap_fragment" ]
            #THREE.ShaderChunk[ "lights_phong_fragment" ]

            "vec3 viewPosition = normalize( vViewPosition );"
            "vec3 normal = normalize( vNormal );",

            "#ifdef USE_ENVMAP"
                "vec3 reflectVec;"

                "#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP )",

                    "vec3 objectNormal = normalize( vObjectNormal );",
                    "objectNormal = perturbNormal2Arb( -viewPosition, objectNormal );"
                    "vec3 cameraToVertex = normalize( vWorldPosition - cameraPosition );",

                    # "if ( useRefract ) {",
                        # "reflectVec = refract( cameraToVertex, objectNormal, refractionRatio );",
                    # "} else { ",
                        "reflectVec = reflect( cameraToVertex, objectNormal );",
                    # "}",
                "#else",
                    "reflectVec = vReflect;"
                "#endif",

                "vec3 sunNormal = normalize( vec3( cubeX, cubeY, cubeZ ) );"
                "reflectVec = reflect( reflectVec, sunNormal );",

                "#ifdef DOUBLE_SIDED"
                    "float flipNormal = ( -1.0 + 2.0 * float( gl_FrontFacing ) );"
                    "vec4 envColor  = textureCube( envMap,  flipNormal * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );"
                    "vec4 specColor = textureCube( specMap, flipNormal * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );"
                "#else"
                    "vec4 envColor  = textureCube( envMap,  vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );"
                    "vec4 specColor = textureCube( specMap, vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );"
                "#endif"

                "envColor.xyz  *= pow( envColor.xyz, vec3( envmapPow, envmapPow, envmapPow ) );"
                "envColor.xyz  *= envmapMul;"

                "specColor.xyz  = pow( specColor.xyz, vec3( specmapPow, specmapPow, specmapPow ) );"
                "specColor.xyz *= specmapMul;"

                # Envmap * Spec
                "gl_FragColor.xyz *= mix( vec3(1.0, 1.0, 1.0), envColor.xyz, envmapMix);"
                "gl_FragColor.xyz *= specColor.xyz;"

                # Old Daniele
                
                # FRESNEL
                #"float fresnelFactor = 1.0;"
                #"#ifdef USE_MAP"
                    #"fresnelFactor = clamp( 1.0 - texture2D( tAux, vUv ).r , 0.0, 1.0);"
                #"#else"
                    #"fresnelFactor = 1.0;"
                #"#endif"

                #"float fresnelPow =  fresnelPower + ( 5.0 * fresnelFactor );"
                #"#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP )",
                    #"normal = perturbNormal2Arb( -viewPosition, normal );"
                #"#endif"

                #"float fresnel;"
                #"#ifdef DOUBLE_SIDED"
                    #"fresnel = pow( 1.0 + dot( -viewPosition , normalize(flipNormal * normal) ), fresnelPow );" 
                #"#else"
                    #"fresnel = pow( 1.0 + dot( -viewPosition , normal ), fresnelPow );" 
                #"#endif"
                #"fresnel = clamp( fresnel, 0.0, 1.0 );"

                # combine using fresnel term and specularStrength instaead of simple "specular"
                # also multiply specular color to final result
                #"float specularStrength = 1.0;"
                #"#ifdef USE_SPECULARMAP"
                    #"gl_FragColor.xyz = mix( gl_FragColor.xyz, cubeColor.xyz * texelSpecular.xyz ,  fresnel * specularStrength   );"
                #"#else"
                    #"gl_FragColor.xyz = mix( gl_FragColor.xyz, cubeColor.xyz,  fresnel * specularStrength  );"
                #"#endif"

            "#endif"
            
            # THREE.ShaderChunk[ "shadowmap_fragment" ]
            # THREE.ShaderChunk[ "linear_to_gamma_fragment" ]

            # "#ifdef GAMMA_OUTPUT",

                # "float d = 1.0/1.8;"
                # "gl_FragColor.rgb = pow( gl_FragColor.rgb , vec3(0.5555555,0.5555555,0.5555555) );"

                # filmic color grade
                # "gl_FragColor *= 16;  // Hardcoded Exposure Adjustment"
                # "float3 x = max(0,gl_FragColor-0.004);"
                # "gl_FragColor = (x*(6.2*x+.5))/(x*(6.2*x+1.7)+0.06);"
            # "#endif"            

            # THREE.ShaderChunk[ "color_fragment" ]
            THREE.ShaderChunk[ "fog_fragment" ]

        "}"

    ].join("\n")