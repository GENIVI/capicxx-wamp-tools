/* Copyright (C) 2017 itemis AG
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef ExampleInterfaceSTUBIMPL_H_
#define ExampleInterfaceSTUBIMPL_H_

#include "v0/testcases/example77/ExampleInterfaceStub.hpp"

namespace v0 {
namespace testcases {
namespace example77 {

class ExampleInterfaceStubImpl : public ExampleInterfaceStub {
public:
	ExampleInterfaceStubImpl();
    virtual ~ExampleInterfaceStubImpl();

    virtual RemoteEventHandlerType* initStubAdapter(const std::shared_ptr<StubAdapterType> &_stubAdapter);

    virtual const CommonAPI::Version& getInterfaceVersion(std::shared_ptr<CommonAPI::ClientId> clientId);

    /// This is the method that will be called on remote calls on the method play.
    virtual void play(const std::shared_ptr<CommonAPI::ClientId> _client, playReply_t _reply);
    /// This is the method that will be called on remote calls on the method add2.
    virtual void add2(const std::shared_ptr<CommonAPI::ClientId> _client, int64_t _left, int64_t _right, add2Reply_t _reply);
    /// This is the method that will be called on remote calls on the method add2struct.
    virtual void add2struct(const std::shared_ptr<CommonAPI::ClientId> _client, ExampleInterface::Summands _s, add2structReply_t _reply);
    /// This is the method that will be called on remote calls on the method add2nestedStruct.
    virtual void add2nestedStruct(const std::shared_ptr<CommonAPI::ClientId> _client, ExampleInterface::Params _p, add2nestedStructReply_t _reply);

private:
};

} // namespace example77
} // namespace testcases
} // namespace v0

#endif /* ExampleInterfaceSTUBIMPL_H_ */
