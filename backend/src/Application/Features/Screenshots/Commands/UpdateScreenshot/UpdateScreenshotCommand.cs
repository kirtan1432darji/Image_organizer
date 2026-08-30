using FluentValidation;
using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Screenshots.Commands.UpdateScreenshot;

public record UpdateScreenshotCommand(Guid Id, UpdateScreenshotRequestDto Request) : IRequest<ScreenshotDto>;

public class UpdateScreenshotCommandValidator : AbstractValidator<UpdateScreenshotCommand>
{
    public UpdateScreenshotCommandValidator()
    {
        RuleFor(v => v.Id).NotEmpty().WithMessage("Screenshot Id is required.");
        RuleFor(v => v.Request).NotNull().WithMessage("Update request is required.");
    }
}

public class UpdateScreenshotCommandHandler : IRequestHandler<UpdateScreenshotCommand, ScreenshotDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public UpdateScreenshotCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<ScreenshotDto> Handle(UpdateScreenshotCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var screenshot = await _unitOfWork.Screenshots.GetWithDetailsByIdAsync(request.Id, userId, cancellationToken);

        if (screenshot == null)
        {
            throw new NotFoundException(nameof(Screenshot), request.Id);
        }

        var req = request.Request;

        if (req.CategoryId.HasValue)
        {
            screenshot.CategoryId = req.CategoryId.Value;
            screenshot.ScreenshotCategories.Clear();
            screenshot.ScreenshotCategories.Add(new ScreenshotCategory
            {
                ScreenshotId = screenshot.Id,
                CategoryId = req.CategoryId.Value
            });
        }

        if (req.SubCategoryId.HasValue)
        {
            screenshot.SubCategoryId = req.SubCategoryId.Value;
        }

        if (req.IsFavorite.HasValue)
        {
            screenshot.IsFavorite = req.IsFavorite.Value;
        }

        if (req.Tags != null)
        {
            screenshot.ScreenshotTags.Clear();
            var tags = await _unitOfWork.Tags.GetOrCreateTagsAsync(req.Tags, userId, cancellationToken);
            foreach (var tag in tags)
            {
                screenshot.ScreenshotTags.Add(new ScreenshotTag
                {
                    ScreenshotId = screenshot.Id,
                    TagId = tag.Id
                });
            }
        }

        screenshot.UpdatedDate = DateTime.UtcNow;
        _unitOfWork.Screenshots.Update(screenshot);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var updated = await _unitOfWork.Screenshots.GetWithDetailsByIdAsync(screenshot.Id, userId, cancellationToken);
        return _mapper.Map<ScreenshotDto>(updated ?? screenshot);
    }
}
