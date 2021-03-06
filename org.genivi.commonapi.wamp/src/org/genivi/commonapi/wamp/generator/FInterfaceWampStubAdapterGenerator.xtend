package org.genivi.commonapi.wamp.generator

import java.util.List
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FArgument
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModelElement
import org.franca.core.franca.FTypedElement
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.genivi.commonapi.core.generator.FTypeGenerator
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.wamp.deployment.PropertyAccessor
import org.genivi.commonapi.wamp.preferences.FPreferencesWamp
import org.genivi.commonapi.wamp.preferences.PreferenceConstantsWamp

import static extension org.franca.core.framework.FrancaHelpers.*

class FInterfaceWampStubAdapterGenerator {
	@Inject private extension FrancaGeneratorExtensions
	@Inject private extension FrancaWampGeneratorExtensions
	@Inject private extension FrancaWampTypeExtensions
	//@Inject private extension FrancaWampDeploymentAccessorHelper
	@Inject private extension FInterfaceWampTypesSupportGenerator

	def generateWampStubAdapter(FInterface _interface, IFileSystemAccess fileSystemAccess, PropertyAccessor deploymentAccessor,  List<FDProvider> providers, IResource modelid) {

		if(FPreferencesWamp::getInstance.getPreference(PreferenceConstantsWamp::P_GENERATE_CODE_WAMP, "true").equals("true")) {
			fileSystemAccess.generateFile(_interface.wampStubAdapterHeaderPath, PreferenceConstantsWamp.P_OUTPUT_STUBS_WAMP,
					_interface.generateWampStubAdapterHeader(deploymentAccessor, modelid))
			fileSystemAccess.generateFile(_interface.wampStubAdapterSourcePath,  PreferenceConstantsWamp.P_OUTPUT_STUBS_WAMP,
					_interface.generateWampStubAdapterSource(deploymentAccessor, providers, modelid))
		}
		else {
			// feature: suppress code generation
			fileSystemAccess.generateFile(_interface.wampStubAdapterHeaderPath, PreferenceConstantsWamp.P_OUTPUT_STUBS_WAMP, PreferenceConstantsWamp::NO_CODE)
			fileSystemAccess.generateFile(_interface.wampStubAdapterSourcePath,  PreferenceConstantsWamp.P_OUTPUT_STUBS_WAMP, PreferenceConstantsWamp::NO_CODE)
		}
	}


	def private generateWampStubAdapterHeader(FInterface _interface,
											  PropertyAccessor deploymentAccessor,
											  IResource modelid ) '''
		«generateCommonApiWampLicenseHeader()»
		«FTypeGenerator::generateComments(_interface, false)»
		#ifndef «_interface.defineName»_WAMP_STUB_ADAPTER_HPP_
		#define «_interface.defineName»_WAMP_STUB_ADAPTER_HPP_

		#include "«_interface.stubHeaderPath»"
		«IF _interface.base != null»
			#include "«_interface.base.wampStubAdapterHeaderPath»"
		«ENDIF»
		//#include "«_interface.wampDeploymentHeaderPath»"

		#if !defined (COMMONAPI_INTERNAL_COMPILATION)
		#define COMMONAPI_INTERNAL_COMPILATION
		#endif

		#include <CommonAPI/Wamp/WampFactory.hpp>
		«IF !_interface.managedInterfaces.empty»
			#include <CommonAPI/Wamp/WampObjectManager.hpp>
		«ENDIF»
		#include <CommonAPI/Wamp/WampStubAdapterHelper.hpp>
		#include <CommonAPI/Wamp/WampStubAdapter.hpp>
		//#include <CommonAPI/Wamp/WampDeployment.hpp>

		#include <CommonAPI/Wamp/WampConnection.hpp>
		#include <CommonAPI/Wamp/WampClientId.hpp>

		#undef COMMONAPI_INTERNAL_COMPILATION

		#include <autobahn/autobahn.hpp>

		«_interface.generateVersionNamespaceBegin»
		«_interface.model.generateNamespaceBeginDeclaration»

		typedef CommonAPI::Wamp::WampStubAdapterHelper<«_interface.stubClassName»> «_interface.wampStubAdapterHelperClassName»;

		class «_interface.wampStubAdapterClassNameInternal»
			: public virtual «_interface.stubAdapterClassName»,
			  public «_interface.wampStubAdapterHelperClassName»«IF _interface.base != null»,
			  public «_interface.base.getTypeCollectionName(_interface)»WampStubAdapterInternal«ENDIF»
		{
		public:
			«_interface.wampStubAdapterClassNameInternal»(
				const CommonAPI::Wamp::WampAddress &_address,
				const std::shared_ptr<CommonAPI::Wamp::WampProxyConnection> &_connection,
				const std::shared_ptr<CommonAPI::StubBase> &_stub);

			~«_interface.wampStubAdapterClassNameInternal»();

			//////////////////////////////////////////////////////////////////////////////////////////

			virtual void provideRemoteMethods();

			«FOR method : _interface.methods»
			void wrap_«method.name»(autobahn::wamp_invocation invocation);
			«ENDFOR»

			«FOR broadcast: _interface.broadcasts»
				«FTypeGenerator::generateComments(broadcast, false)»
				«IF broadcast.selective»
					void «broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, _interface)»);
					void «broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, _interface, true)»);
					void «broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success);
					void «broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId);
					std::shared_ptr<CommonAPI::ClientIdList> const «broadcast.stubAdapterClassSubscribersMethodName»();
                «ELSE»
					void «broadcast.stubAdapterClassFireEventMethodName»(«broadcast.generateArgs(_interface)»);
                «ENDIF»

			«ENDFOR»

			//////////////////////////////////////////////////////////////////////////////////////////

			const «_interface.wampStubAdapterHelperClassName»::StubDispatcherTable& getStubDispatcherTable();
			const CommonAPI::Wamp::StubAttributeTable& getStubAttributeTable();

			void deactivateManagedInstances();

			static CommonAPI::Wamp::WampGetAttributeStubDispatcher<
				«_interface.stubFullClassName»,
				CommonAPI::Version
			> get«_interface.elementName»InterfaceVersionStubDispatcher;

		private:
			«_interface.wampStubAdapterHelperClassName»::StubDispatcherTable stubDispatcherTable_;
			CommonAPI::Wamp::StubAttributeTable stubAttributeTable_;
			«FOR broadcast: _interface.broadcasts.filter[selective]»
				std::mutex «broadcast.className»Mutex_;
				//bool «broadcast.className»Handler(CommonAPI::Wamp::client_id_t _client, bool subscribe);
    	    «ENDFOR»
		};

		«FOR broadcast : _interface.broadcasts»
			«IF broadcast.selective»
				void «_interface.wampStubAdapterClassNameInternal»::«broadcast.stubAdapterClassFireSelectiveMethodName»(«generateFireSelectiveSignatur(broadcast, _interface)») {
					// TODO
				}
				
				void «_interface.wampStubAdapterClassNameInternal»::«broadcast.stubAdapterClassSendSelectiveMethodName»(«generateSendSelectiveSignatur(broadcast, _interface, false)») {
					// TODO
				}
				
				void «_interface.wampStubAdapterClassNameInternal»::«broadcast.subscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId, bool& success) {
					// TODO
				}
				
				void «_interface.wampStubAdapterClassNameInternal»::«broadcast.unsubscribeSelectiveMethodName»(const std::shared_ptr<CommonAPI::ClientId> clientId) {
					// TODO
				}
				
				std::shared_ptr<CommonAPI::ClientIdList> const «_interface.wampStubAdapterClassNameInternal»::«broadcast.stubAdapterClassSubscribersMethodName»() {
					std::lock_guard<std::mutex> itsLock(«broadcast.className»Mutex_);
					return std::make_shared<CommonAPI::ClientIdList>(*«broadcast.stubAdapterClassSubscriberListPropertyName»);
				}
			«ELSE»
				void «_interface.wampStubAdapterClassNameInternal»::«broadcast.stubAdapterClassFireEventMethodName»(«broadcast.generateArgs(_interface)») {
				    //CommonAPI::Deployable< int64_t, CommonAPI::Wamp::IntegerDeployment<int64_t>> deployed_arg1(_arg1, static_cast< CommonAPI::Wamp::IntegerDeployment<int64_t>* >(nullptr));
				
				    std::cout << "«_interface.wampStubAdapterClassNameInternal»::«broadcast.stubAdapterClassFireEventMethodName»(" << «broadcast.outArgs.map[debug].join(' << ", " << ')» << ")" << std::endl;
				    CommonAPI::Wamp::WampStubTopicHelper::publishTopic(
				    		*this,
							getWampAddress().getRealm() + ".«broadcast.name»",
							std::make_tuple(«FOR it : broadcast.outArgs SEPARATOR ', '»«elementName»«IF type.isEnumeration».value_«ENDIF»«ENDFOR»)
				    );
				}
			«ENDIF»
			
		«ENDFOR»

		class «_interface.wampStubAdapterClassName»
			: public «_interface.wampStubAdapterClassNameInternal»,
			  public std::enable_shared_from_this<«_interface.wampStubAdapterClassName»> {
		public:
			«_interface.wampStubAdapterClassName»(const CommonAPI::Wamp::WampAddress &_address,
													const std::shared_ptr<CommonAPI::Wamp::WampProxyConnection> &_connection,
													const std::shared_ptr<CommonAPI::StubBase> &_stub) 
				: CommonAPI::Wamp::WampStubAdapter(_address, _connection, false),
				  «_interface.wampStubAdapterClassNameInternal»(_address, _connection, _stub) {
				std::cout << "«_interface.wampStubAdapterClassName» constructor called" << std::endl;
			}
		};

		«_interface.model.generateNamespaceEndDeclaration»
		«_interface.generateVersionNamespaceEnd»

		#endif // «_interface.defineName»_WAMP_STUB_ADAPTER_HPP_
	'''

	def private generateArgs(FBroadcast broadcast, FInterface _interface) {
		'''«broadcast.outArgs.map['const ' + getTypeName(_interface, true) + '& ' + elementName].join(', ')»'''
	}

	def private generateWampStubAdapterSource(FInterface _interface, PropertyAccessor deploymentAccessor,  List<FDProvider> providers, IResource modelid) '''
		«generateCommonApiWampLicenseHeader()»

		#include "«_interface.headerPath»"
		#include "«_interface.wampStubAdapterHeaderPath»"
		#include "«_interface.wampTypesSupportHeaderPath»"

		#include <functional>
		
		«_interface.generateVersionNamespaceBegin»
		«_interface.model.generateNamespaceBeginDeclaration»

		std::shared_ptr<CommonAPI::Wamp::WampStubAdapter> create«_interface.wampStubAdapterClassName»(
								const CommonAPI::Wamp::WampAddress &_address,
								const std::shared_ptr<CommonAPI::Wamp::WampProxyConnection> &_connection,
								const std::shared_ptr<CommonAPI::StubBase> &_stub) {
			std::cout << "create«_interface.wampStubAdapterClassName» called" << std::endl;
			return std::make_shared<«_interface.wampStubAdapterClassName»>(_address, _connection, _stub);
		}

		INITIALIZER(register«_interface.wampStubAdapterClassName») {
			CommonAPI::Wamp::Factory::get()->registerStubAdapterCreateMethod(
				«_interface.name»::getInterface(), &create«_interface.wampStubAdapterClassName»);
			std::cout << "registerStubAdapterCreateMethod(create«_interface.wampStubAdapterClassName»)" << std::endl;
		}

		«_interface.wampStubAdapterClassNameInternal»::~«_interface.wampStubAdapterClassNameInternal»() {
			«FOR broadcast : _interface.broadcasts.filter[selective]»
				//CommonAPI::Wamp::WampStubAdapter::connection_->unregisterSubscriptionHandler(CommonAPI::Wamp::WampStubAdapter::getWampAddress());
			«ENDFOR»
			deactivateManagedInstances();
			«_interface.wampStubAdapterHelperClassName»::deinit();
		}

		void «_interface.wampStubAdapterClassNameInternal»::deactivateManagedInstances() {

		}

		CommonAPI::Wamp::WampGetAttributeStubDispatcher<
			«_interface.stubFullClassName»,
			CommonAPI::Version
		> «_interface.wampStubAdapterClassNameInternal»::get«_interface.elementName»InterfaceVersionStubDispatcher(&«_interface.stubClassName»::getInterfaceVersion, "uu");


		const «_interface.wampStubAdapterHelperClassName»::StubDispatcherTable& «_interface.wampStubAdapterClassNameInternal»::getStubDispatcherTable() {
			return stubDispatcherTable_;
		}

		const CommonAPI::Wamp::StubAttributeTable& «_interface.wampStubAdapterClassNameInternal»::getStubAttributeTable() {
			return stubAttributeTable_;
		}

		«_interface.wampStubAdapterClassNameInternal»::«_interface.wampStubAdapterClassNameInternal»(
				const CommonAPI::Wamp::WampAddress &_address,
				const std::shared_ptr<CommonAPI::Wamp::WampProxyConnection> &_connection,
				const std::shared_ptr<CommonAPI::StubBase> &_stub)
			: CommonAPI::Wamp::WampStubAdapter(_address, _connection, false),
			  «_interface.wampStubAdapterHelperClassName»(_address, _connection, std::dynamic_pointer_cast<«_interface.stubClassName»>(_stub), false),
			  stubDispatcherTable_({ /* TODO: is stubDispatcherTable needed at all? */ }),
				stubAttributeTable_() {
			std::cout << "«_interface.wampStubAdapterClassNameInternal» constructor called" << std::endl;
			stubDispatcherTable_.insert({ { "getInterfaceVersion", "" }, &/*namespace::*/«_interface.wampStubAdapterClassNameInternal»::get«_interface.elementName»InterfaceVersionStubDispatcher });
		}
		
		
		//////////////////////////////////////////////////////////////////////////////////////////

		void «_interface.wampStubAdapterClassNameInternal»::provideRemoteMethods() {
			std::cout << "provideRemoteMethods called" << std::endl;

			«FOR m : _interface.methods»
			CommonAPI::Wamp::WampMethodWithReplyStubDispatcher<«_interface.wampStubAdapterClassNameInternal»>
				::provideRemoteMethod(*this,
					"«m.name»", &«_interface.wampStubAdapterClassNameInternal»::wrap_«m.name»);
			«ENDFOR»
		}

		«FOR m : _interface.methods»
			«m.genWrapperMethod(_interface)»
			
		«ENDFOR»

		«_interface.model.generateNamespaceEndDeclaration»
		«_interface.generateVersionNamespaceEnd»
	'''

	def private genWrapperMethod(FMethod m, FInterface _interface) {
		val et = m.errorType
		val hasErr = !et.empty
		'''
			void «_interface.wampStubAdapterClassNameInternal»::wrap_«m.name»(autobahn::wamp_invocation invocation) {
				std::cout << "«_interface.wampStubAdapterClassNameInternal»::wrap_«m.name» called" << std::endl;
				auto clientNumber = invocation->argument<uint32_t>(0);
				«FOR arg : m.inArgs»
					auto «arg.name» = invocation->argument<«arg.getTypename(_interface)»>(«m.inArgs.indexOf(arg) + 1»);
				«ENDFOR»
				std::cerr << "Procedure " << getWampAddress().getRealm() << ".«m.name» invoked (clientNumber=" << clientNumber << ") "«m.inArgs.arglist1» << std::endl;
				std::shared_ptr<CommonAPI::Wamp::WampClientId> clientId = std::make_shared<CommonAPI::Wamp::WampClientId>(clientNumber);
				«IF hasErr»
					«et» err;
				«ENDIF»
				«FOR arg : m.outArgs»
					«arg.getTypename(_interface)» «arg.name»;
				«ENDFOR»
				stub_->«m.name»(
					clientId«m.inArgs.map[', ' + name].join»
					«IF !m.isFireAndForget»
					, [&](«IF hasErr»«et» _error«IF !m.outArgs.empty», «ENDIF»«ENDIF»«m.outArgs.arglist2(_interface)») {
						«IF hasErr»err=_error;«ENDIF»
						«m.outArgs.arglist3»
					}
					«ENDIF»
				);
				«IF !m.outArgs.empty»
				invocation->result(std::make_tuple(«IF hasErr»err.value_, «ENDIF»«m.outArgs.arglist4»));
				«ENDIF»
			}
		'''
	}
	
	def private arglist1(List<FArgument> args) {
		args.filter[!type.isCompound].map[''' << "«IF args.indexOf(it)>0», «ENDIF»«name»=" << «debug»'''].join
	}

	def private arglist2(List<FArgument> args, FModelElement _container) {
		args.map[getTypename(_container) + " _" + name].join(", ")
	}

	def private arglist3(List<FArgument> args) {
		args.map[name + "=_" + name + "; "].join
	}

	def private arglist4(List<FArgument> args) '''«FOR it : args SEPARATOR ', '»«name»«IF isRealStruct».values_«ENDIF»«ENDFOR»'''

	def private getDebug(FArgument arg) {
		if (arg.type.isArray || arg.isArray || arg.type.isMap)
			'''"[<" << «arg.elementName».size() << ">]"'''
		else if (arg.type.isCompound)
			'''"[<«arg.type.actualDerived.name»>]"'''
		else
			'''«arg.elementName»'''
	}

	def private isRealStruct(FTypedElement elem) {
		elem.type.isStruct && !elem.isArray
	}

//		void initialize«_interface.wampStubAdapterClassName»() {
//            «FOR p : providers»
//				«val PropertyAccessor providerAccessor = new PropertyAccessor(new FDeployedProvider(p))»
//                «FOR i : p.instances.filter[target == _interface]»
//					CommonAPI::SomeIP::AddressTranslator::get()->insert(
//					"local:«_interface.fullyQualifiedNameWithVersion»:«providerAccessor.getInstanceId(i)»",
//					«555», 0x«Integer.toHexString(
//                            777)», «_interface.version.major», «_interface.version.minor»);
//                «ENDFOR»
//            «ENDFOR»
//			CommonAPI::Wamp::Factory::get()->registerStubAdapterCreateMethod(
//			«_interface.elementName»::getInterface(),
//				&create«_interface.wampStubAdapterClassName»);
//		}


//	def private getAbsoluteNamespace(FModelElement fModelElement) {
//		fModelElement.model.name.replace('.', '::')
//	}

	def private wampStubAdapterHeaderFile(FInterface _interface) {
		_interface.elementName + "WampStubAdapter.hpp"
	}

	def private wampStubAdapterHeaderPath(FInterface _interface) {
		_interface.versionPathPrefix + _interface.model.directoryPath + '/' + _interface.wampStubAdapterHeaderFile
	}

	def private wampStubAdapterSourceFile(FInterface _interface) {
		_interface.elementName + "WampStubAdapter.cpp"
	}

	def private wampStubAdapterSourcePath(FInterface _interface) {
		_interface.versionPathPrefix + _interface.model.directoryPath + '/' + _interface.wampStubAdapterSourceFile
	}

	def private wampStubAdapterClassName(FInterface _interface) {
		_interface.elementName + 'WampStubAdapter'
	}

	def private wampStubAdapterClassNameInternal(FInterface _interface) {
		_interface.wampStubAdapterClassName + 'Internal'
	}

	def private wampStubAdapterHelperClassName(FInterface _interface) {
		_interface.elementName + 'WampStubAdapterHelper'
	}

	def private getAllInTypes(FMethod fMethod) {
		fMethod.inArgs.map[getTypeName(fMethod, true)].join(', ')
	}

//	def private getAllOutTypes(FMethod fMethod) {
//		var types = fMethod.outArgs.map[getTypeName(fMethod, true)].join(', ')
//
//		if (fMethod.hasError) {
//			if (!fMethod.outArgs.empty)
//				types = ', ' + types
//			types = fMethod.getErrorNameReference(fMethod.eContainer) + types
//		}
//
//		return types
//	}

	def private wampStubDispatcherVariable(FMethod fMethod) {
		fMethod.elementName.toFirstLower + 'StubDispatcher'
	}

//	def private wampGetStubDispatcherVariable(FAttribute fAttribute) {
//		fAttribute.wampGetMethodName + 'StubDispatcher'
//	}
//
//	def private wampSetStubDispatcherVariable(FAttribute fAttribute) {
//		fAttribute.wampSetMethodName + 'StubDispatcher'
//	}
//
//	def private wampStubDispatcherVariable(FBroadcast fBroadcast) {
//		var returnVal = fBroadcast.elementName.toFirstLower
//
//		if(fBroadcast.selective)
//			returnVal = returnVal + 'Selective'
//
//		returnVal = returnVal + 'StubDispatcher'
//
//		return returnVal
//	}

//	def private wampStubDispatcherVariableSubscribe(FBroadcast fBroadcast) {
//		"subscribe" + fBroadcast.wampStubDispatcherVariable.toFirstUpper
//	}

//	def private wampStubDispatcherVariableUnsubscribe(FBroadcast fBroadcast) {
//		"unsubscribe" + fBroadcast.wampStubDispatcherVariable.toFirstUpper
//	}

	var nextSectionInDispatcherNeedsComma = false;

	def void setNextSectionInDispatcherNeedsComma(boolean newValue) {
		nextSectionInDispatcherNeedsComma = newValue
	}

//	def private generateFireChangedMethodBody(FAttribute attribute, FInterface _interface, PropertyAccessor deploymentAccessor) '''
//		«val String deploymentType = attribute.getDeploymentType(_interface, true)»
//		«val String deployment = attribute.getDeploymentRef(attribute.array, null, _interface, deploymentAccessor)»
//		«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
//		CommonAPI::Deployable< «attribute.getTypeName(attribute, true)», «deploymentType»> deployedValue(value, «IF deployment != ""»«deployment»«ELSE»nullptr«ENDIF»);
//		«ENDIF»
//		CommonAPI::Wamp::WampStubSignalHelper<CommonAPI::Wamp::WampSerializableArguments<
//		«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»
//			CommonAPI::Deployable<
//				«attribute.getTypeName(_interface, true)»,
//				«deploymentType»
//			>
//		«ELSE»
//			«attribute.getTypeName(_interface, true)»
//		«ENDIF»
//		>>
//			::sendSignal(
//				*this,
//				"«attribute.wampSignalName»",
//				"«attribute.wampSignature(deploymentAccessor)»",
//				«IF deploymentType != "CommonAPI::EmptyDeployment" && deploymentType != ""»deployedValue«ELSE»value«ENDIF»
//
//		);
//	'''

//	def private generateStubAttributeTableInitializer(FInterface _interface, PropertyAccessor deploymentAccessor) '''
//		«IF !_interface.attributes.empty»
//			«FOR attribute : _interface.attributes»
//				«_interface.generateStubAttributeTableInitializerEntry(attribute)»
//			«ENDFOR»
//		«ENDIF»
//	'''
//
//	def private generateStubAttributeTableInitializerEntry(FInterface _interface, FAttribute fAttribute) '''
//		«_interface.wampStubAdapterHelperClassName»::addAttributeDispatcher("«fAttribute.elementName»",
//				&«_interface.absoluteNamespace»::«_interface.wampStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fAttribute.wampGetStubDispatcherVariable»,
//				«IF fAttribute.readonly»(CommonAPI::Wamp::WampSetFreedesktopAttributeStubDispatcher<«_interface.stubFullClassName», int>*)NULL«ELSE»&«_interface.absoluteNamespace»::«_interface.wampStubAdapterClassNameInternal»<_Stub, _Stubs...>::«fAttribute.wampSetStubDispatcherVariable»«ENDIF»
//			);
//	'''
	
//	def private generateErrorReplyCallback(FBroadcast fBroadcast, FInterface _interface, FMethod fMethod, PropertyAccessor deploymentAccessor) '''
//			
//		static void «fBroadcast.errorReplyCallbackName(deploymentAccessor)»(«fBroadcast.generateErrorReplyCallbackSignature(fMethod, deploymentAccessor)») {
//			«IF fBroadcast.errorArgs(deploymentAccessor).size > 1»
//				auto args = std::make_tuple(
//					«fBroadcast.errorArgs(deploymentAccessor).map[it.getDeployable(_interface, deploymentAccessor) + '(' + '_' + it.elementName + ', ' + getDeploymentRef(it.array, fBroadcast, _interface, deploymentAccessor) + ')'].join(",\n")  + ");"»
//			«ELSE»
//				auto args = std::make_tuple();
//			«ENDIF»
//			«fMethod.wampStubDispatcherVariable».sendErrorReply(_callId, "«fBroadcast.wampErrorReplyOutSignature(fMethod, deploymentAccessor)»", _«fBroadcast.errorName(deploymentAccessor)», args);
//		}
//	'''
	
}
