#!/usr/bin/env python3
"""Generate the committed Xcode project without third-party project tools."""
from pathlib import Path
import hashlib, json, plistlib
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'ValkyrieLearn.xcodeproj'
PROJECT.mkdir(exist_ok=True)
objects = {}
def uid(name): return hashlib.sha256(name.encode()).hexdigest()[:24].upper()
def put(object_name, isa, **fields):
    key = uid(object_name); objects[key] = {'isa': isa, **fields}; return key

def quote(value):
    if isinstance(value, dict): return '{ ' + ' '.join(f'{k} = {quote(v)};' for k,v in value.items()) + ' }'
    if isinstance(value, list): return '(' + ', '.join(quote(x) for x in value) + (',)' if value else ')')
    if isinstance(value, int): return str(value)
    return json.dumps(str(value))

app_files = sorted(p for folder in ['App','Game','Parent','Persistence'] for p in (ROOT/'ValkyrieLearn'/folder).rglob('*.swift'))
core_tests = sorted((ROOT/'ValkyrieLearn/Tests/LearningCoreTests').glob('*.swift'))
store_tests = sorted((ROOT/'ValkyrieLearn/Tests/PersistenceTests').glob('*.swift'))
resources = sorted((ROOT/'ValkyrieLearn/Resources').glob('*.wav'))
file_refs = {}
for p in app_files + core_tests + store_tests + resources:
    rel = str(p.relative_to(ROOT))
    file_refs[rel] = put(rel, 'PBXFileReference', lastKnownFileType='sourcecode.swift' if p.suffix=='.swift' else 'audio.wav', path=rel, sourceTree='<group>')
# Include learning sources and curriculum for browsing; package owns their compilation.
for p in sorted((ROOT/'ValkyrieLearn/Learning').rglob('*.swift')) + sorted((ROOT/'ValkyrieLearn/Curriculum').rglob('*.swift')):
    rel = str(p.relative_to(ROOT)); file_refs[rel] = put(rel, 'PBXFileReference', lastKnownFileType='sourcecode.swift', path=rel, sourceTree='<group>')
source_group = put('Sources','PBXGroup', children=list(file_refs.values()), name='Native sources', sourceTree='<group>')
products = []
targets = []
package = put('LocalPackage', 'XCLocalSwiftPackageReference', relativePath='.')
app_id = uid('Target:ValkyrieLearn')
for name,files,kind in [('ValkyrieLearn',app_files,'application'),('LearningCoreTests',core_tests,'bundle.unit-test'),('PersistenceTests',store_tests,'bundle.unit-test')]:
    product = put('Product:'+name,'PBXFileReference', explicitFileType='wrapper.application' if kind=='application' else 'wrapper.cfbundle',
                  path=name+('.app' if kind=='application' else '.xctest'), sourceTree='BUILT_PRODUCTS_DIR')
    products.append(product)
    source_builds = [put('Build:'+name+str(p),'PBXBuildFile',fileRef=file_refs[str(p.relative_to(ROOT))]) for p in files]
    sources = put('Sources:'+name,'PBXSourcesBuildPhase',buildActionMask=2147483647,files=source_builds,runOnlyForDeploymentPostprocessing=0)
    product_dependency = put('PackageProduct:'+name,'XCSwiftPackageProductDependency',package=package,productName='LearningCore')
    framework_build = put('LinkPackage:'+name,'PBXBuildFile',productRef=product_dependency)
    frameworks = put('Frameworks:'+name,'PBXFrameworksBuildPhase',buildActionMask=2147483647,files=[framework_build],runOnlyForDeploymentPostprocessing=0)
    resource_builds = [put('Resource:'+str(p),'PBXBuildFile',fileRef=file_refs[str(p.relative_to(ROOT))]) for p in resources] if kind=='application' else []
    resource_phase = put('Resources:'+name,'PBXResourcesBuildPhase',buildActionMask=2147483647,files=resource_builds,runOnlyForDeploymentPostprocessing=0)
    configs=[]
    for config in ['Debug','Release']:
        settings = {'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.valkyrielearn.'+name,
                    'SWIFT_VERSION':'5.0','IPHONEOS_DEPLOYMENT_TARGET':'17.0','TARGETED_DEVICE_FAMILY':'2',
                    'SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','CODE_SIGN_STYLE':'Automatic',
                    'SWIFT_OPTIMIZATION_LEVEL':'-Onone' if config=='Debug' else '-O',
                    'DEBUG_INFORMATION_FORMAT':'dwarf' if config=='Debug' else 'dwarf-with-dsym',
                    'SWIFT_ACTIVE_COMPILATION_CONDITIONS':'DEBUG' if config=='Debug' else '',
                    'ENABLE_TESTABILITY':'YES' if config=='Debug' else 'NO'}
        if kind=='application':
            settings.update({'INFOPLIST_FILE':'ValkyrieLearn/Resources/Info.plist','GENERATE_INFOPLIST_FILE':'NO',
                             'MARKETING_VERSION':'0.1.0','CURRENT_PROJECT_VERSION':'1','ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS':'YES'})
        else: settings['GENERATE_INFOPLIST_FILE']='YES'
        if name=='PersistenceTests':
            settings.update({'TEST_HOST':'$(BUILT_PRODUCTS_DIR)/ValkyrieLearn.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/ValkyrieLearn', 'BUNDLE_LOADER':'$(TEST_HOST)'})
        configs.append(put('Config:'+name+config,'XCBuildConfiguration',buildSettings=settings,name=config))
    config_list=put('ConfigList:'+name,'XCConfigurationList',buildConfigurations=configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
    dependencies=[]
    if name=='PersistenceTests':
        proxy=put('AppProxy','PBXContainerItemProxy',containerPortal=uid('Project'),proxyType=1,remoteGlobalIDString=app_id,remoteInfo='ValkyrieLearn')
        dependencies=[put('AppDependency','PBXTargetDependency',target=app_id,targetProxy=proxy)]
    targets.append(put('Target:'+name,'PBXNativeTarget',buildConfigurationList=config_list,buildPhases=[sources,frameworks,resource_phase],buildRules=[],dependencies=dependencies,
                       name=name,productName=name,productReference=product,productType='com.apple.product-type.'+kind,packageProductDependencies=[product_dependency]))
products_group=put('Products','PBXGroup',children=products,name='Products',sourceTree='<group>')
main_group=put('MainGroup','PBXGroup',children=[source_group,products_group],sourceTree='<group>')
project_configs=[]
for config in ['Debug','Release']:
    project_configs.append(put('ProjectConfig:'+config,'XCBuildConfiguration',name=config,buildSettings={
        'SDKROOT':'iphoneos','CLANG_ENABLE_MODULES':'YES','CLANG_ENABLE_OBJC_ARC':'YES','SWIFT_VERSION':'5.0',
        'IPHONEOS_DEPLOYMENT_TARGET':'17.0','SWIFT_STRICT_CONCURRENCY':'targeted',
        'ENABLE_TESTABILITY':'YES' if config=='Debug' else 'NO'}))
project_config_list=put('ProjectConfigs','XCConfigurationList',buildConfigurations=project_configs,defaultConfigurationIsVisible=0,defaultConfigurationName='Release')
project_id=put('Project','PBXProject',attributes={'BuildIndependentTargetsInParallel':'YES','LastUpgradeCheck':'1600'},buildConfigurationList=project_config_list,
              compatibilityVersion='Xcode 14.0',developmentRegion='en',hasScannedForEncodings=0,knownRegions=['en','Base'],mainGroup=main_group,
              productRefGroup=products_group,projectDirPath='',projectRoot='',targets=targets,packageReferences=[package])
text='// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'
text+='\n'.join(f'{key} = {quote(value)};' for key,value in sorted(objects.items()))
text+='\n}; rootObject = '+project_id+'; }\n'
(PROJECT/'project.pbxproj').write_text(text)

scheme=ET.Element('Scheme',LastUpgradeVersion='1600',version='1.7')
def reference(parent,name):
    ET.SubElement(parent,'BuildableReference',BuildableIdentifier='primary',BlueprintIdentifier=uid('Target:'+name),
                  BuildableName=name+('.app' if name=='ValkyrieLearn' else '.xctest'),BlueprintName=name,ReferencedContainer='container:ValkyrieLearn.xcodeproj')
build=ET.SubElement(scheme,'BuildAction',parallelizeBuildables='YES',buildImplicitDependencies='YES')
entries=ET.SubElement(build,'BuildActionEntries')
for name in ['ValkyrieLearn','LearningCoreTests','PersistenceTests']:
    entry=ET.SubElement(entries,'BuildActionEntry',buildForTesting='YES',buildForRunning='YES' if name=='ValkyrieLearn' else 'NO',buildForProfiling='YES' if name=='ValkyrieLearn' else 'NO',buildForArchiving='YES' if name=='ValkyrieLearn' else 'NO',buildForAnalyzing='YES')
    reference(entry,name)
test=ET.SubElement(scheme,'TestAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',shouldUseLaunchSchemeArgsEnv='YES')
testables=ET.SubElement(test,'Testables')
for name in ['LearningCoreTests','PersistenceTests']:
    reference(ET.SubElement(testables,'TestableReference',skipped='NO'),name)
launch=ET.SubElement(scheme,'LaunchAction',buildConfiguration='Debug',selectedDebuggerIdentifier='Xcode.DebuggerFoundation.Debugger.LLDB',selectedLauncherIdentifier='Xcode.IDEFoundation.Launcher.LLDB',launchStyle='0',useCustomWorkingDirectory='NO',ignoresPersistentStateOnLaunch='NO',debugServiceExtension='internal',allowLocationSimulation='NO')
reference(ET.SubElement(launch,'BuildableProductRunnable',runnableDebuggingMode='0'),'ValkyrieLearn')
ET.SubElement(scheme,'ProfileAction',buildConfiguration='Release',shouldUseLaunchSchemeArgsEnv='YES',savedToolIdentifier='',useCustomWorkingDirectory='NO')
ET.SubElement(scheme,'AnalyzeAction',buildConfiguration='Debug'); ET.SubElement(scheme,'ArchiveAction',buildConfiguration='Release',revealArchiveInOrganizer='YES')
scheme_dir=PROJECT/'xcshareddata/xcschemes';scheme_dir.mkdir(parents=True,exist_ok=True)
ET.indent(scheme)
ET.ElementTree(scheme).write(scheme_dir/'ValkyrieLearn.xcscheme',encoding='UTF-8',xml_declaration=True)
print(f'Generated {PROJECT.name}: {len(app_files)} app sources, {len(core_tests)+len(store_tests)} test sources.')
