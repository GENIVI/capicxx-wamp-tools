/*
* This file was generated by the CommonAPI Generators.
* Used org.genivi.commonapi.core (standalone).
* Used org.franca.core 0.9.1.201412191134.
*
* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
* If a copy of the MPL was not distributed with this file, You can obtain one at
* http://mozilla.org/MPL/2.0/.
*/
#ifndef EXAMPLE_Example_Interface_WAMP_STUB_ADAPTER_HPP_
#define EXAMPLE_Example_Interface_WAMP_STUB_ADAPTER_HPP_

#include "example/ExampleInterfaceStub.hpp"
//#include "example/ExampleInterfaceWampDeployment.hpp"

#if !defined (COMMONAPI_INTERNAL_COMPILATION)
#define COMMONAPI_INTERNAL_COMPILATION
#endif

#include <CommonAPI/Wamp/WampFactory.hpp>
#include <CommonAPI/Wamp/WampStubAdapterHelper.hpp>
#include <CommonAPI/Wamp/WampStubAdapter.hpp>
//#include <CommonAPI/Wamp/WampDeployment.hpp>

#include <autobahn/autobahn.hpp>

#undef COMMONAPI_INTERNAL_COMPILATION

namespace example {

typedef CommonAPI::Wamp::WampStubAdapterHelper<ExampleInterfaceStub> ExampleInterfaceWampStubAdapterHelper;

class ExampleInterfaceWampStubAdapterInternal
	: public virtual ExampleInterfaceStubAdapter,
	  public ExampleInterfaceWampStubAdapterHelper
{
public:
	ExampleInterfaceWampStubAdapterInternal(
		const CommonAPI::Wamp::WampAddress &_address,
		const std::shared_ptr<CommonAPI::Wamp::WampProxyConnection> &_connection,
		const std::shared_ptr<CommonAPI::StubBase> &_stub);

	~ExampleInterfaceWampStubAdapterInternal();

	//////////////////////////////////////////////////////////////////////////////////////////

	virtual void provideRemoteMethods();

	void wrap_play(autobahn::wamp_invocation invocation);
	void wrap_add2(autobahn::wamp_invocation invocation);
	void wrap_add2struct(autobahn::wamp_invocation invocation);
	void wrap_add2nestedStruct(autobahn::wamp_invocation invocation);

	//////////////////////////////////////////////////////////////////////////////////////////

	const ExampleInterfaceWampStubAdapterHelper::StubDispatcherTable& getStubDispatcherTable();
	const CommonAPI::Wamp::StubAttributeTable& getStubAttributeTable();

	void deactivateManagedInstances();

	static CommonAPI::Wamp::WampGetAttributeStubDispatcher<
		::example::ExampleInterfaceStub,
		CommonAPI::Version
	> getExampleInterfaceInterfaceVersionStubDispatcher;

	static CommonAPI::Wamp::MethodWithReplyStubDispatcher<
		::example::ExampleInterfaceStub,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>
	> playStubDispatcher;
	static CommonAPI::Wamp::MethodWithReplyStubDispatcher<
		::example::ExampleInterfaceStub,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>
	> add2StubDispatcher;
	static CommonAPI::Wamp::MethodWithReplyStubDispatcher<
		::example::ExampleInterfaceStub,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>
	> add2structStubDispatcher;
	static CommonAPI::Wamp::MethodWithReplyStubDispatcher<
		::example::ExampleInterfaceStub,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>,
		std::tuple<>
	> add2nestedStructStubDispatcher;

private:
	ExampleInterfaceWampStubAdapterHelper::StubDispatcherTable stubDispatcherTable_;
	CommonAPI::Wamp::StubAttributeTable stubAttributeTable_;
};


class ExampleInterfaceWampStubAdapter
	: public ExampleInterfaceWampStubAdapterInternal,
	  public std::enable_shared_from_this<ExampleInterfaceWampStubAdapter> {
public:
	ExampleInterfaceWampStubAdapter(
		const CommonAPI::Wamp::WampAddress &_address,
		const std::shared_ptr<CommonAPI::Wamp::WampProxyConnection> &_connection,
		const std::shared_ptr<CommonAPI::StubBase> &_stub) 
		: CommonAPI::Wamp::WampStubAdapter(_address, _connection, false),
		  ExampleInterfaceWampStubAdapterInternal(_address, _connection, _stub) {
		std::cout << "ExampleInterfaceWampStubAdapter constructor called" << std::endl;
	}
};

} // namespace example

#endif // EXAMPLE_Example_Interface_WAMP_STUB_ADAPTER_HPP_